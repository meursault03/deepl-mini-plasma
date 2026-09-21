# DeepL Mini

A lightweight KDE Plasma 6 widget for translating text with the DeepL API.

DeepL Mini uses a native QML popup. It does not embed Chromium or QtWebEngine. A small Python helper is started only for an API request, then exits.

## Features

- Automatic source-language detection.
- A searchable selector containing the current stable DeepL target-language catalog.
- Optional automatic translation with a configurable typing delay.
- Manual translation, clear, and copy controls.
- Explicit handling for DeepL API errors, including monthly quota exhaustion.
- No background translation process while the widget is idle.

## API key security

Every user configures their own DeepL API key from the widget's **Configure… → DeepL API** page or the key button in the popup.

The key is entered in a secure system dialog with a hidden API-key field and stored in a Secret Service-compatible keyring, such as KDE Wallet. It is read only by the one-shot helper and sent only in the HTTPS `Authorization` header to `https://api-free.deepl.com/v2/translate`.

The API key is never written to Plasma's configuration file, the widget directory, command-line arguments, logs, or Git. Do not add a key to an issue, commit, screenshot, or pull request.

## Requirements

- KDE Plasma 6.
- Python 3 (only the standard library is used).
- `secret-tool` from libsecret, with a Secret Service-compatible keyring available in the user session.
- Zenity or KDialog for the secure API-key entry dialog.
- A personal DeepL API Free key.

## Install from source

```sh
git clone https://github.com/meursault03/deepl-mini-plasma.git deepl-mini
cd deepl-mini
kpackagetool6 --type Plasma/Applet --install "$PWD"
```

If an older local version is installed, use `--upgrade` instead of `--install`.

Then add **DeepL Mini** from Plasma's widget picker. Open its configuration page, select **DeepL API**, and choose **Set or replace API key**.

## Development checks

```sh
python3 -m py_compile contents/scripts/deepl-mini.py
python3 -m unittest discover -s tests -v
xmllint --noout contents/config/main.xml
/usr/lib/qt6/bin/qmllint contents/ui/*.qml
```

## Language catalog

The widget ships a static snapshot of DeepL's stable text-translation target languages. This keeps the popup fast and avoids a network request solely to populate the picker. The snapshot is updated in releases when DeepL adds or changes supported languages.

## Continuous integration

GitHub Actions runs the helper tests, catalog checks, XML validation, QML linting, and Plasma package installation check for every push and pull request.

## License

MIT. See [LICENSE](LICENSE).
