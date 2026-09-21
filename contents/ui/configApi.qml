import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import "Command.js" as Command

KCM.SimpleKCM {
    id: root

    property string activeCommand: ""
    property string statusText: ""
    property bool statusIsError: false
    property bool busy: false
    property bool keyConfigured: false

    readonly property string helperPath: Qt.resolvedUrl("../scripts/deepl-mini.py")
        .toString().replace(/^file:\/\//, "")
    readonly property string setupCommand: Command.build(["python3", helperPath, "--setup"])
    readonly property string keyStatusCommand: Command.build(["python3", helperPath, "--key-status"])

    function run(command) {
        if (activeCommand)
            executable.disconnectSource(activeCommand)
        activeCommand = command
        busy = true
        executable.connectSource(command)
    }

    function checkKeyring() {
        run(keyStatusCommand)
    }

    function configureKey() {
        statusText = ""
        run(setupCommand)
    }

    Component.onCompleted: checkKeyring()

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            const exitCode = Number(data["exit code"] || 0)
            const stdout = String(data.stdout || "").trim()
            const stderr = String(data.stderr || "").trim()
            const wasSetup = sourceName === root.setupCommand
            disconnectSource(sourceName)

            if (sourceName !== root.activeCommand)
                return

            root.activeCommand = ""
            root.busy = false

            if (wasSetup) {
                root.statusIsError = exitCode !== 0 && exitCode !== 2
                root.statusText = exitCode === 0
                    ? i18n("API key saved in the system keyring.")
                    : (exitCode === 2
                        ? i18n("API key setup was canceled.")
                        : (stderr || i18n("The API key could not be saved.")))
                if (exitCode === 0)
                    root.checkKeyring()
                return
            }

            if (!stdout) {
                root.keyConfigured = false
                root.statusIsError = true
                root.statusText = stderr || i18n("The keyring check returned no response.")
                return
            }

            try {
                const response = JSON.parse(stdout)
                root.keyConfigured = Boolean(response.configured)
                root.statusIsError = !response.ok
                root.statusText = response.ok
                    ? i18n("An API key is configured in the system keyring.")
                    : (response.error || i18n("No API key is configured yet."))
            } catch (error) {
                root.keyConfigured = false
                root.statusIsError = true
                root.statusText = i18n("The keyring check returned an invalid response.")
            }
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Heading {
            Layout.fillWidth: true
            level: 2
            text: i18n("Your DeepL API key")
        }

        Label {
            Layout.fillWidth: true
            text: i18n("Each user supplies their own DeepL API key. A Free API key works with this widget.")
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true

            Button {
                text: i18n("Set or replace API key")
                icon.name: "dialog-password"
                enabled: !root.busy
                onClicked: root.configureKey()
            }

            Button {
                text: i18n("Check keyring")
                icon.name: "view-refresh"
                enabled: !root.busy
                onClicked: root.checkKeyring()
            }

            BusyIndicator {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                running: root.busy
                visible: root.busy
            }
        }

        Label {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.statusText
            wrapMode: Text.WordWrap
            color: root.statusIsError ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.positiveTextColor
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        Label {
            Layout.fillWidth: true
            text: i18n("Selecting “Set or replace API key” opens a secure system dialog with a hidden API-key field. The key is saved only in your Secret Service-compatible keyring. It is never stored in the widget settings or included in a Git repository.")
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.disabledTextColor
        }

        Button {
            text: i18n("Get a DeepL API key")
            icon.name: "internet-services"
            onClicked: Qt.openUrlExternally("https://www.deepl.com/pro-api")
        }
    }
}
