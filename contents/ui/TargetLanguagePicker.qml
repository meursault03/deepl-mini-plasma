import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "TargetLanguages.js" as TargetLanguages

Item {
    id: root

    property string selectedCode: "EN-US"
    readonly property string selectedLabel: TargetLanguages.labelFor(selectedCode)
    signal languageSelected(string code)

    implicitWidth: languageButton.implicitWidth
    implicitHeight: languageButton.implicitHeight

    Button {
        id: languageButton
        anchors.fill: parent
        text: root.selectedLabel
        icon.name: "arrow-down"
        display: AbstractButton.TextBesideIcon
        enabled: root.enabled
        Accessible.name: i18n("Target language")
        onClicked: languagePopup.open()
    }

    Popup {
        id: languagePopup
        parent: root
        x: Math.max(0, root.width - width)
        y: root.height + Kirigami.Units.smallSpacing
        width: Math.max(root.width, 320)
        padding: Kirigami.Units.smallSpacing
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property var filteredLanguages: TargetLanguages.filter(searchField.text)

        onOpened: searchField.forceActiveFocus()

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: i18n("Search languages…")
                Accessible.name: i18n("Search target languages")
                onTextChanged: languageList.currentIndex = 0
                onAccepted: {
                    if (languagePopup.filteredLanguages.length > 0) {
                        root.languageSelected(languagePopup.filteredLanguages[0].code)
                        languagePopup.close()
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                visible: languagePopup.filteredLanguages.length === 0
                text: i18n("No matching languages")
                color: Kirigami.Theme.disabledTextColor
            }

            ListView {
                id: languageList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, Kirigami.Units.gridUnit * 12)
                clip: true
                model: languagePopup.filteredLanguages
                currentIndex: 0
                keyNavigationEnabled: true

                delegate: ItemDelegate {
                    required property var modelData
                    width: ListView.view.width
                    text: modelData.name + " (" + modelData.code + ")"
                    highlighted: root.selectedCode === modelData.code
                    onClicked: {
                        root.languageSelected(modelData.code)
                        languagePopup.close()
                    }
                }
            }
        }
    }
}
