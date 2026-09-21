import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import "TargetLanguages.js" as TargetLanguages

KCM.SimpleKCM {
    id: root

    property string cfg_targetLanguage: "EN-US"
    property alias cfg_autoTranslate: autoTranslate.checked
    property alias cfg_debounceMilliseconds: debounceMilliseconds.value

    Component.onCompleted: cfg_targetLanguage = TargetLanguages.normalize(cfg_targetLanguage)

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        TargetLanguagePicker {
            id: targetLanguage
            Kirigami.FormData.label: i18n("Default target language:")
            Layout.fillWidth: true
            selectedCode: TargetLanguages.normalize(root.cfg_targetLanguage)
            onLanguageSelected: (code) => root.cfg_targetLanguage = code
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
