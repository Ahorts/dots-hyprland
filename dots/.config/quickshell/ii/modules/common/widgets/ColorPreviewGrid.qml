import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common

/*
    Almost all of the custom color schemes (latte.json, samurai.json etc.) are gotten from https://github.com/snowarch/quickshell-ii-niri/blob/main/modules/common/ThemePresets.qml
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