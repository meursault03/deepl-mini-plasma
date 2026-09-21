import contextlib
import importlib.util
import io
import json
import subprocess
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
from urllib.error import HTTPError


HELPER_PATH = Path(__file__).parents[1] / "contents/scripts/deepl-mini.py"


def load_helper():
    spec = importlib.util.spec_from_file_location("deepl_mini_test", HELPER_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class FakeResponse:
    def __init__(self, body):
        self.body = body

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return False

    def read(self):
        return self.body


class DeepLMiniTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.helper = load_helper()

    def invoke_translation(self, response_or_error, text="Olá", target="EN-US"):
        captured = {}

        def fake_open(request, timeout):
            captured["url"] = request.full_url
            captured["payload"] = json.loads(request.data.decode("utf-8"))
            captured["headers"] = dict(request.header_items())
            captured["timeout"] = timeout
            if isinstance(response_or_error, Exception):
                raise response_or_error
            return FakeResponse(response_or_error)

        output = io.StringIO()
        with patch.object(self.helper, "read_api_key", return_value=("test-api-key", None)), \
             patch.object(self.helper.urllib.request, "urlopen", fake_open), \
             contextlib.redirect_stdout(output):
            self.assertEqual(self.helper.translate(17, text, target), 0)
        return json.loads(output.getvalue()), captured

    def test_translation_uses_free_endpoint_without_source_language(self):
        response, captured = self.invoke_translation(
            b'{"translations":[{"text":"Hello","detected_source_language":"PT"}]}'
        )

        self.assertTrue(response["ok"])
        self.assertEqual(response["translation"], "Hello")
        self.assertEqual(captured["url"], "https://api-free.deepl.com/v2/translate")
        self.assertEqual(captured["payload"], {"text": ["Olá"], "target_lang": "EN-US"})
        self.assertNotIn("source_lang", captured["payload"])
        self.assertEqual(captured["headers"]["Authorization"], "DeepL-Auth-Key test-api-key")
        self.assertEqual(captured["headers"]["User-agent"], "DeepL-Mini/3.2.0")
        self.assertEqual(captured["timeout"], 8)

    def test_malformed_translation_response_returns_structured_error(self):
        response, _captured = self.invoke_translation(b'{"translations":[null]}')

        self.assertFalse(response["ok"])
        self.assertEqual(response["error"], "The DeepL API did not return a translation.")

    def test_http_error_is_mapped(self):
        http_error = HTTPError(
            "https://api-free.deepl.com/v2/translate",
            456,
            "Quota exceeded",
            {},
            io.BytesIO(b'{"message":"Quota exceeded"}'),
        )
        response, _captured = self.invoke_translation(http_error)

        self.assertFalse(response["ok"])
        self.assertEqual(response["error_code"], 456)
        self.assertEqual(response["error"], "The monthly DeepL API limit has been reached.")

    def test_rejects_oversize_utf8_payload_before_reading_key(self):
        output = io.StringIO()
        with patch.object(self.helper, "read_api_key") as read_key, contextlib.redirect_stdout(output):
            self.helper.translate(18, "😀" * 40000, "EN-US")

        response = json.loads(output.getvalue())
        self.assertFalse(response["ok"])
        self.assertEqual(response["error_code"], 413)
        read_key.assert_not_called()

    def test_rejects_invalid_target_code_without_api_call(self):
        output = io.StringIO()
        with patch.object(self.helper, "read_api_key") as read_key, contextlib.redirect_stdout(output):
            self.helper.translate(19, "Hello", "EN-US;rm")

        response = json.loads(output.getvalue())
        self.assertFalse(response["ok"])
        self.assertEqual(response["error"], "The selected target language is not supported.")
        read_key.assert_not_called()

    def test_key_status_never_outputs_the_key(self):
        output = io.StringIO()
        with patch.object(self.helper, "read_api_key", return_value=("hidden-test-key", None)), \
             contextlib.redirect_stdout(output):
            self.helper.emit_key_status()

        self.assertEqual(json.loads(output.getvalue()), {"ok": True, "configured": True, "error": ""})
        self.assertNotIn("hidden-test-key", output.getvalue())

    def test_setup_sends_key_only_over_stdin(self):
        calls = []

        def fake_run(command, **kwargs):
            calls.append((command, kwargs))
            if command[0] == "zenity":
                return SimpleNamespace(returncode=0, stdout="test-api-key\n", stderr="")
            return SimpleNamespace(returncode=0, stdout="", stderr="")

        with patch.object(self.helper.subprocess, "run", fake_run):
            self.assertEqual(self.helper.setup_api_key(), 0)

        prompt_command, _prompt_kwargs = calls[0]
        store_command, store_kwargs = calls[1]
        self.assertIn("--add-password=API key", prompt_command)
        self.assertEqual(store_command[:3], ["secret-tool", "store", "--label=DeepL Mini API key"])
        self.assertEqual(store_kwargs["input"], "test-api-key\n")
        self.assertTrue(all("test-api-key" not in part for part in prompt_command + store_command))

    def test_setup_falls_back_to_kdialog(self):
        commands = []

        def fake_run(command, **kwargs):
            commands.append(command)
            if command[0] == "zenity":
                raise FileNotFoundError
            if command[0] == "kdialog":
                return SimpleNamespace(returncode=1, stdout="", stderr="")
            raise AssertionError(command)

        with patch.object(self.helper.subprocess, "run", fake_run):
            self.assertEqual(self.helper.setup_api_key(), 2)

        self.assertEqual(commands[1][0], "kdialog")
        self.assertIn("Enter your DeepL API key:", commands[1])


if __name__ == "__main__":
    unittest.main()
