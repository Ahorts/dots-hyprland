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

    readonly property list<string> builtinColorSchemes: ["angel_light", "angel", "ayu", "cobalt2", "cursor", "dracula", "flexoki", "frappe", "github", "gruvbox", "kanagawa", "latte", "macchiato", "material_ocean", "matrix", "mercury", "mocha", "nord", "open_code", "orng", "osaka_jade", "rose_pine", "sakura", "samurai", "synthwave84", "vercel", "vesper", "zen_burn", "zen_garden"]
    property list<string> customColorSchemes: Config.options.appearance.palette.customColorSchemes ?? ""

    readonly property list<string> wallpaperColorSchemes: ["scheme-auto", "scheme-content", "scheme-tonal-spot", "scheme-fidelity", "scheme-fruit-salad", "scheme-expressive", "scheme-rainbow", "scheme-neutral", "scheme-monochrome"]

    property bool customTheme: false
    property list<string> colorSchemes: customTheme ? [...customColorSchemes, ...builtinColorSchemes] : root.wallpaperColorSchemes

    function formatText (text) {
        if (customTheme) return text.charAt(0).toUpperCase() + text.slice(1);
        const sliced = text.split("-").slice(1).join(" ");
        return sliced.charAt(0).toUpperCase() + sliced.slice(1);
    }

    Repeater {
        model: root.colorSchemes
        delegate: ColorPreviewButton {
            colorScheme: modelData
            colorSchemeDisplayName: formatText(modelData)
            customTheme: root.customTheme
        }
    }
}