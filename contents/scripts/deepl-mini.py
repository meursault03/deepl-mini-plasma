#!/usr/bin/env python3
"""One-shot DeepL API client used by the lightweight Plasma widget."""

import argparse
import json
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request


API_URL = "https://api-free.deepl.com/v2/translate"
VERSION = "3.2.0"
REQUEST_TIMEOUT_SECONDS = 8
MAX_REQUEST_BYTES = 128 * 1024
SECRET_ATTRIBUTES = ("service", "deepl-mini", "account", "default")
TARGET_LANGUAGE_PATTERN = re.compile(r"^[A-Z]{2,3}(?:-[A-Z0-9]{2,4})?$")

ERROR_MESSAGES = {
    400: "DeepL rejected the text or request.",
    403: "The DeepL API key is invalid or unauthorized.",
    404: "The DeepL API endpoint could not be found.",
    413: "The translation request is too large.",
    414: "The translation request is too large.",
    429: "Too many requests to the DeepL API. Please try again shortly.",
    456: "The monthly DeepL API limit has been reached.",
    500: "The DeepL service returned a temporary error.",
    504: "The DeepL service took too long to respond.",
    529: "The DeepL service is temporarily overloaded.",
}


def emit(payload):
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))


def emit_error(request_id, message, code=None):
    payload = {
        "ok": False,
        "request_id": request_id,
        "error": message,
    }
    if code is not None:
        payload["error_code"] = code
    emit(payload)


def read_api_key():
    try:
        result = subprocess.run(
            ["secret-tool", "lookup", *SECRET_ATTRIBUTES],
            capture_output=True,
            text=True,
            timeout=3,
            check=False,
        )
    except FileNotFoundError:
        return None, "Secret Service is not available on this system."
    except subprocess.TimeoutExpired:
        return None, "The system keyring took too long to respond."

    key = result.stdout.strip()
    if result.returncode != 0 or not key:
        return None, "Configure a DeepL API key in the widget first."
    return key, None


def emit_key_status():
    api_key, error = read_api_key()
    emit(
        {
            "ok": api_key is not None,
            "configured": api_key is not None,
            "error": error or "",
        }
    )
    return 0


def prompt_for_api_key():
    prompt_commands = (
        [
            "zenity",
            "--forms",
            "--title=DeepL Mini — Set API key",
            "--text=Enter your DeepL API key. It will be stored securely in your system keyring.",
            "--add-password=API key",
            "--ok-label=Save API key",
            "--cancel-label=Cancel",
            "--width=480",
        ],
        [
            "kdialog",
            "--title",
            "DeepL Mini — Set API key",
            "--password",
            "Enter your DeepL API key:",
        ],
    )
    for command in prompt_commands:
        try:
            return subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=120,
                check=False,
            ), None
        except FileNotFoundError:
            continue
        except subprocess.TimeoutExpired:
            return None, "API key setup timed out."
    return None, "Install Zenity or KDialog to configure an API key."


def setup_api_key():
    prompt, prompt_error = prompt_for_api_key()
    if prompt_error:
        print(prompt_error, file=sys.stderr)
        return 1

    if prompt.returncode != 0 or not prompt.stdout.strip():
        return 2

    try:
        stored = subprocess.run(
            [
                "secret-tool",
                "store",
                "--label=DeepL Mini API key",
                *SECRET_ATTRIBUTES,
            ],
            input=prompt.stdout.strip() + "\n",
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
    except FileNotFoundError:
        print("Secret Service is not available on this system.", file=sys.stderr)
        return 1
    except subprocess.TimeoutExpired:
        print("The system keyring took too long to save the API key.", file=sys.stderr)
        return 1

    if stored.returncode != 0:
        print(stored.stderr.strip() or "The API key could not be saved.", file=sys.stderr)
        return stored.returncode or 1
    return 0


def response_message(status, body):
    if status in ERROR_MESSAGES:
        return ERROR_MESSAGES[status]
    try:
        parsed = json.loads(body.decode("utf-8", errors="replace"))
        detail = parsed.get("message")
        if detail:
            return str(detail)
    except (TypeError, ValueError, UnicodeDecodeError):
        pass
    return f"The DeepL API returned HTTP {status}."


def extract_translation(parsed):
    if not isinstance(parsed, dict):
        return None
    translations = parsed.get("translations")
    if not isinstance(translations, list) or not translations:
        return None
    first_translation = translations[0]
    if not isinstance(first_translation, dict):
        return None
    text = first_translation.get("text")
    if not isinstance(text, str) or not text:
        return None
    detected_source = first_translation.get("detected_source_language", "")
    return text, detected_source if isinstance(detected_source, str) else ""


def translate(request_id, encoded_text, target_language):
    try:
        text = urllib.parse.unquote(encoded_text)
    except (TypeError, ValueError):
        emit_error(request_id, "The input text could not be read.")
        return 0

    if not text.strip():
        emit({"ok": True, "request_id": request_id, "translation": ""})
        return 0
    target_language = str(target_language).upper()
    if not TARGET_LANGUAGE_PATTERN.fullmatch(target_language):
        emit_error(request_id, "The selected target language is not supported.")
        return 0

    payload = json.dumps(
        {
            "text": [text],
            "target_lang": target_language,
        },
        ensure_ascii=False,
    ).encode("utf-8")
    if len(payload) > MAX_REQUEST_BYTES:
        emit_error(request_id, "The translation request is too large.", 413)
        return 0

    api_key, key_error = read_api_key()
    if key_error:
        emit_error(request_id, key_error)
        return 0

    request = urllib.request.Request(
        API_URL,
        data=payload,
        headers={
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": f"DeepL-Auth-Key {api_key}",
            "User-Agent": f"DeepL-Mini/{VERSION}",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT_SECONDS) as response:
            body = response.read()
        parsed = json.loads(body.decode("utf-8"))
        translation = extract_translation(parsed)
        if translation is None:
            emit_error(request_id, "The DeepL API did not return a translation.")
            return 0
        translated_text, detected_source = translation
        emit(
            {
                "ok": True,
                "request_id": request_id,
                "translation": translated_text,
                "detected_source": detected_source,
            }
        )
    except urllib.error.HTTPError as error:
        body = error.read()
        emit_error(request_id, response_message(error.code, body), error.code)
    except urllib.error.URLError:
        emit_error(request_id, "Could not connect to the DeepL API.")
    except TimeoutError:
        emit_error(request_id, "The DeepL API exceeded the 8-second timeout.")
    except (UnicodeDecodeError, json.JSONDecodeError):
        emit_error(request_id, "The DeepL API returned an invalid response.")
    except OSError:
        emit_error(request_id, "Could not complete the request to the DeepL API.")
    except Exception:
        emit_error(request_id, "The DeepL helper encountered an unexpected error.")

    return 0


def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--key-status", action="store_true")
    parser.add_argument("--setup", action="store_true")
    parser.add_argument("--request-id", type=int, default=0)
    parser.add_argument("--text-urlencoded")
    parser.add_argument("--target-lang", default="EN-US")
    args = parser.parse_args()

    if args.check:
        print(f"DeepL Mini API client: {API_URL}")
        return 0
    if args.key_status:
        return emit_key_status()
    if args.setup:
        return setup_api_key()
    if args.text_urlencoded is None:
        print("usage: deepl-mini.py --request-id N --text-urlencoded TEXT", file=sys.stderr)
        return 2
    return translate(args.request_id, args.text_urlencoded, args.target_lang)


if __name__ == "__main__":
    raise SystemExit(main())
