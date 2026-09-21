import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Preferences")
        icon: "configure"
        source: "configGeneral.qml"
    }

    ConfigCategory {
        name: i18n("DeepL API")
        icon: "dialog-password"
        source: "configApi.qml"
    }
}
