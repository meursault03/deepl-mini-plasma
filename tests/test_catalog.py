import re
import unittest
from pathlib import Path


CATALOG_PATH = Path(__file__).parents[1] / "contents/ui/TargetLanguages.js"
MAIN_QML_PATH = Path(__file__).parents[1] / "contents/ui/main.qml"
CONFIG_API_QML_PATH = Path(__file__).parents[1] / "contents/ui/configApi.qml"


class TargetLanguageCatalogTests(unittest.TestCase):
    def setUp(self):
        self.source = CATALOG_PATH.read_text(encoding="utf-8")
        self.entries = re.findall(
            r'\{ code: "([A-Z0-9-]+)", name: "([^"]+)" \}', self.source
        )

    def test_catalog_has_a_unique_full_snapshot(self):
        codes = [code for code, _name in self.entries]
        self.assertGreaterEqual(len(codes), 100)
        self.assertEqual(len(codes), len(set(codes)))
        self.assertIn("EN-US", codes)
        self.assertIn("PT-BR", codes)
        self.assertIn("ZH-HANT", codes)

    def test_catalog_exposes_fallback_and_search_helpers(self):
        self.assertIn('return contains(normalized) ? normalized : "EN-US"', self.source)
        self.assertIn("function filter(query)", self.source)
        self.assertIn("language.name.toLowerCase().indexOf(normalized)", self.source)

    def test_helper_commands_are_built_with_shared_shell_quoting(self):
        main_qml = MAIN_QML_PATH.read_text(encoding="utf-8")
        config_api_qml = CONFIG_API_QML_PATH.read_text(encoding="utf-8")

        self.assertIn('import "Command.js" as Command', main_qml)
        self.assertIn('import "Command.js" as Command', config_api_qml)
        self.assertIn("activeCommand = Command.build(", main_qml)
        self.assertNotIn('" --target-lang " + targetLanguage', main_qml)


if __name__ == "__main__":
    unittest.main()
