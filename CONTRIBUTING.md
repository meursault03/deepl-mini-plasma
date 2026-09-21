# Contributing

Thank you for improving DeepL Mini.

## Before opening a pull request

1. Do not include an API key, Secret Service export, Plasma configuration file, or screenshot containing credentials.
2. Keep the popup native QML. Do not introduce QtWebEngine, Chromium, a persistent daemon, or a Python dependency installed with `pip`.
3. Keep all user-facing text in English.
4. Run the checks from the README.
5. Explain UI or network behavior changes in the pull request description.

## Design constraints

- `source_lang` must be omitted so DeepL performs source-language detection.
- The Free API endpoint is `https://api-free.deepl.com/v2/translate`.
- Authentication belongs only in the `Authorization: DeepL-Auth-Key …` HTTP header.
- API-key input must not be passed in process arguments or saved in Plasma configuration.
- The widget must remain responsive during a failed or slow network request.
