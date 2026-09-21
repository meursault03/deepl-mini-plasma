import QtQuick
import QtQuick.Controls
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: root

    property string cfg_targetLanguage: "EN-US"
    property alias cfg_autoTranslate: autoTranslate.checked
    property alias cfg_debounceMilliseconds: debounceMilliseconds.value

    readonly property var languageCodes: ["EN-US", "EN-GB", "PT-BR", "ES", "FR", "DE", "IT", "JA"]
    readonly property var languageLabels: [
        i18n("English (US)"), i18n("English (UK)"),
        i18n("Portuguese (Brazil)"), i18n("Spanish"),
        i18n("French"), i18n("German"), i18n("Italian"), i18n("Japanese")
    ]

    function syncTargetLanguage() {
        const index = languageCodes.indexOf(cfg_targetLanguage)
        targetLanguage.currentIndex = index >= 0 ? index : 0
    }

    onCfg_targetLanguageChanged: syncTargetLanguage()
    Component.onCompleted: syncTargetLanguage()

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        ComboBox {
            id: targetLanguage
            Kirigami.FormData.label: i18n("Default target language:")
            model: root.languageLabels
            onActivated: root.cfg_targetLanguage = root.languageCodes[currentIndex]
        }

        Switch {
            id: autoTranslate
            Kirigami.FormData.label: i18n("Translation:")
            text: i18n("Translate automatically after typing stops")
        }

        SpinBox {
            id: debounceMilliseconds
            Kirigami.FormData.label: i18n("Typing delay:")
            from: 200
            to: 3000
            stepSize: 100
            editable: true
        }

        Label {
            text: i18n("Milliseconds to wait before an automatic translation.")
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.disabledTextColor
        }
    }
}
