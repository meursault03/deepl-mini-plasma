# DeepL Mini

A lightweight KDE Plasma 6 widget for translating text with the DeepL API.

DeepL Mini uses a native QML popup. It does not embed Chromium or QtWebEngine. A small Python helper is started only for an API request, then exits.

## Features

- Automatic source-language detection.
- English (US/UK), Portuguese (Brazil), Spanish, French, German, Italian, and Japanese target languages.
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
- `zenity` for the secure API-key entry dialog.
- A personal DeepL API Free key.

## Install from source

```sh
git clone <your-repository-url> deepl-mini
cd deepl-mini
kpackagetool6 --type Plasma/Applet --install "$PWD"
```

If an older local version is installed, use `--upgrade` instead of `--install`.

Then add **DeepL Mini** from Plasma's widget picker. Open its configuration page, select **DeepL API**, and choose **Set or replace API key**.

## Development checks

```sh
python3 -m py_compile contents/scripts/deepl-mini.py
qmllint contents/ui/main.qml contents/ui/configGeneral.qml contents/ui/configApi.qml
kpackagetool6 --type Plasma/Applet --show io.meursault.panel.deeplqt
```

## Publish on GitHub

Before the first public push, make sure no local API key or generated archive is staged:

```sh
git init
git add .
git status
git commit -m "Initial public release"
gh repo create deepl-mini --public --source=. --remote=origin --push
```

Replace `deepl-mini` with the desired repository name. `gh` is optional; creating an empty repository on GitHub and then adding its remote works too.

## License

MIT. See [LICENSE](LICENSE).
