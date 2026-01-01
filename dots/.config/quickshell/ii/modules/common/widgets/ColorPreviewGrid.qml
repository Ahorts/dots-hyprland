import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common

/*
    Almost all of the custom color schemes (latte.json, samurai.json etc.) are gotten from https://github.com/snowarch/quickshell-ii-niri/blob/main/modules/common/ThemePresets.qml

    To add a new custom color scheme:

    1. Get a proper color scheme (in the same format as the default ones) and put in to ~/.config/quickshell/ii/defaults (make sure to backup your theme files yourself, they may get overwritten)
    2. Add the exact name of the json file to the config.json - appearance - customColorSchemes
*/

GridLayout {
    id: root
    implicitWidth: parent.width
    columns: 3

    property bool customTheme: false
    property list<string> colorSchemes: ["scheme-auto", "scheme-content", "scheme-tonal-spot", "scheme-fidelity", "scheme-fruit-salad", "scheme-expressive", "scheme-rainbow", "scheme-neutral", "scheme-monochrome"]

    function formatText (text) {
        if (customTheme) return text.charAt(0).toUpperCase() + text.slice(1);
        const sliced = text.split("-").slice(1).join(" ");
        return sliced.charAt(0).toUpperCase() + sliced.slice(1);
    }

    Repeater {
        model: root.colorSchemes
        delegate: ColorPreviewButton {
            colorScheme: modelData
            colorSchemeDisplayName: Translation.tr(formatText(modelData))
            customTheme: root.customTheme
        }
    }
}