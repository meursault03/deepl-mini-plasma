import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    property string errorText: ""
    property string resultText: ""
    property string activeCommand: ""
    property string lastRequestedText: ""
    property string lastRequestedTargetLanguage: ""
    property string activeRequestText: ""
    property string currentInputText: ""
    property string inputText: ""
    readonly property string targetLanguage: Plasmoid.configuration.targetLanguage || "EN-US"
    readonly property bool autoTranslate: Plasmoid.configuration.autoTranslate !== false
    readonly property int debounceMilliseconds: Math.max(
        200, Number(Plasmoid.configuration.debounceMilliseconds) || 700)
    property int requestId: 0
    property bool busy: false
    property bool configuringKey: false

    readonly property var targetLanguageCodes: ["EN-US", "EN-GB", "PT-BR", "ES", "FR", "DE", "IT", "JA"]
    readonly property var targetLanguageLabels: [
        i18n("English (US)"), i18n("English (UK)"),
        i18n("Portuguese (Brazil)"), i18n("Spanish"),
        i18n("French"), i18n("German"), i18n("Italian"), i18n("Japanese")
    ]

    readonly property string helperPath: Qt.resolvedUrl("../scripts/deepl-mini.py")
        .toString().replace(/^file:\/\//, "")
    readonly property string setupCommand: "python3 \"" + helperPath + "\" --setup"

    function cancelActiveCommand() {
        if (activeCommand)
            executable.disconnectSource(activeCommand)
        activeCommand = ""
        busy = false
        configuringKey = false
    }

    function clearTranslation() {
        requestId += 1
        cancelActiveCommand()
        lastRequestedText = ""
        lastRequestedTargetLanguage = ""
        activeRequestText = ""
        resultText = ""
        errorText = ""
        debounceTimer.stop()
    }

    function handleInputChanged(text) {
        inputText = text
        currentInputText = text.trim()
        errorText = ""
        if (!currentInputText) {
            clearTranslation()
            return
        }
        if (currentInputText !== lastRequestedText)
            resultText = ""
        if (autoTranslate)
            debounceTimer.restart()
        else
            debounceTimer.stop()
    }

    function translateNow() {
        const value = inputText.trim()
        if (!value)
            return clearTranslation()
        if (value === lastRequestedText &&
                targetLanguage === lastRequestedTargetLanguage && resultText)
            return

        cancelActiveCommand()
        requestId += 1
        lastRequestedText = value
        lastRequestedTargetLanguage = targetLanguage
        activeRequestText = value
        resultText = ""
        errorText = ""
        busy = true
        activeCommand = "python3 \"" + helperPath + "\" --request-id " + requestId +
            " --target-lang " + targetLanguage +
            " --text-urlencoded \"" + encodeURIComponent(value) + "\""
        executable.connectSource(activeCommand)
    }

    function setTargetLanguage(language) {
        if (language === targetLanguage)
            return
        Plasmoid.configuration.targetLanguage = language
        lastRequestedText = ""
        lastRequestedTargetLanguage = ""
        resultText = ""
        errorText = ""
        if (currentInputText)
            translateNow()
    }

    function configureKey() {
        cancelActiveCommand()
        configuringKey = true
        busy = true
        errorText = ""
        activeCommand = setupCommand
        executable.connectSource(activeCommand)
    }

    function formatError(code, fallback) {
        switch (Number(code)) {
        case 403:
            return i18n("The DeepL API key is invalid or unauthorized.")
        case 429:
            return i18n("Too many requests. Please try again shortly.")
        case 456:
            return i18n("The monthly DeepL API limit has been reached.")
        case 500:
        case 504:
        case 529:
            return i18n("The DeepL service is temporarily unavailable.")
        default:
            return fallback || i18n("The text could not be translated.")
        }
    }

    toolTipMainText: i18n("DeepL Mini")
    toolTipSubText: errorText || i18n("Translate with DeepL")
    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.contextualActions: []

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            const exitCode = Number(data["exit code"] || 0)
            const stdout = String(data.stdout || "").trim()
            const stderr = String(data.stderr || "").trim()
            disconnectSource(sourceName)

            if (sourceName !== root.activeCommand)
                return

            root.activeCommand = ""
            root.busy = false

            if (root.configuringKey) {
                root.configuringKey = false
                root.errorText = exitCode === 0
                    ? i18n("API key saved in the system keyring.")
                    : i18n("The API key could not be saved.")
                return
            }

            if (!stdout) {
                root.errorText = stderr || i18n("The translation helper returned no response.")
                return
            }

            try {
                const response = JSON.parse(stdout)
                if (Number(response.request_id) !== root.requestId ||
                        root.activeRequestText !== root.currentInputText)
                    return
                if (!response.ok) {
                    root.resultText = ""
                    root.errorText = root.formatError(response.error_code, response.error)
                    return
                }
                root.errorText = ""
                root.resultText = response.translation || ""
            } catch (error) {
                root.errorText = i18n("The DeepL helper returned an invalid response.")
            }
        }
    }

    Timer {
        id: debounceTimer
        interval: root.debounceMilliseconds
        repeat: false
        onTriggered: root.translateNow()
    }

    compactRepresentation: Item {
        Layout.minimumWidth: 76
        Layout.preferredWidth: 76
        Layout.fillHeight: true

        RowLayout {
            anchors.centerIn: parent
            spacing: 4

            Kirigami.Icon {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter
                source: "translate"
                isMask: true
                color: translateMouse.containsMouse
                    ? Kirigami.Theme.highlightColor
                    : Kirigami.Theme.textColor
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignVCenter
                text: "DeepL"
                color: Kirigami.Theme.textColor
                font.family: "Zalando Sans"
                font.pixelSize: 12
                font.weight: Font.Medium
            }
        }

        MouseArea {
            id: translateMouse
            hoverEnabled: true
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = true
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: 420
        Layout.preferredWidth: 420
        Layout.minimumHeight: 430
        Layout.preferredHeight: 430

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents.Label {
                    text: i18n("Detect language  →")
                    font.bold: true
                }

                ComboBox {
                    id: targetSelector
                    Layout.fillWidth: true
                    model: root.targetLanguageLabels
                    currentIndex: root.targetLanguageCodes.indexOf(root.targetLanguage)
                    onActivated: root.setTargetLanguage(root.targetLanguageCodes[currentIndex])
                    Accessible.name: i18n("Target language")
                }

                PlasmaComponents.BusyIndicator {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    running: root.busy
                    visible: root.busy
                }

                PlasmaComponents.ToolButton {
                    icon.name: "configure"
                    text: i18n("Configure API key")
                    display: PlasmaComponents.AbstractButton.IconOnly
                    onClicked: root.configureKey()
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 145
                TextArea {
                    id: sourceText
                    width: parent.width
                    placeholderText: i18n("Type text to translate…")
                    wrapMode: TextArea.Wrap
                    selectByMouse: true
                    onTextChanged: root.handleInputChanged(text)
                }
            }

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents.Button {
                    text: i18n("Translate now")
                    icon.name: "document-edit"
                    enabled: sourceText.text.trim().length > 0 && !root.busy
                    onClicked: root.translateNow()
                }

                PlasmaComponents.Button {
                    text: i18n("Clear")
                    icon.name: "edit-clear"
                    enabled: sourceText.text.length > 0 || root.resultText.length > 0
                    onClicked: sourceText.text = ""
                }
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.errorText
                color: Kirigami.Theme.negativeTextColor
                wrapMode: Text.WordWrap
                visible: text.length > 0
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                TextArea {
                    id: resultTextArea
                    width: parent.width
                    readOnly: true
                    text: root.resultText
                    placeholderText: i18n("Translation will appear here")
                    wrapMode: TextArea.Wrap
                    selectByMouse: true
                    persistentSelection: true
                }
            }

            PlasmaComponents.Button {
                Layout.alignment: Qt.AlignRight
                text: i18n("Copy translation")
                icon.name: "edit-copy"
                enabled: root.resultText.length > 0
                onClicked: {
                    resultTextArea.selectAll()
                    resultTextArea.copy()
                    resultTextArea.deselect()
                }
            }
        }

        Component.onCompleted: sourceText.forceActiveFocus()
    }
}
