import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions


RippleButton {
    id: root

    property string colorScheme: "scheme-auto"
    property color accentColor
    readonly property bool toggled: Config.options.appearance.palette.type === root.colorScheme

    readonly property string wallpaperPath: Config.options.background.wallpaperPath
    readonly property string scriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/generate_colors_material.py`)
    readonly property string grepCommand: "grep -E '^[[:space:]]*(primary|secondary|tertiary)[[:space:]]*:' | grep -oE '#[0-9A-Fa-f]{6}'" // some magic to extract hex colors from the script output
    property string scriptArguments: ` --scheme ${root.colorScheme} --debug | ${root.grepCommand}`

    property string fullCommand: `python3 ${root.scriptPath} --color "$(${root.accentColorCommand})" ${root.scriptArguments}`
    readonly property string accentColorCommand: `python3 ${root.scriptPath} --path ${Config.options.background.wallpaperPath} --debug | grep "Accent color" | awk '{print $NF}'`

    property color primaryColor: "transparent"
    property color secondaryColor: "transparent"
    property color tertiaryColor: "transparent"

    colBackground: toggled ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
    colBackgroundHover: toggled ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer2Hover
    colRipple: toggled ? Appearance.colors.colPrimaryContainerActive : Appearance.colors.colLayer2Active

    buttonRadius: Appearance.rounding.small

    Layout.fillWidth: true
    implicitHeight: 64

    onClicked: {
        Config.options.appearance.palette.type = root.colorScheme;
        Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --noswitch`]);
    }

    Component.onCompleted: colorFetchProc.running = true;
    onWallpaperPathChanged: colorFetchProc.running = true;

    Process {
        id: colorFetchProc
        running: false
        command: [ "bash", "-c", root.fullCommand ]
        stdout: StdioCollector {
            onStreamFinished: {
                const colors = this.text.split("\n")
                root.primaryColor   = colors[0]?.trim()
                root.secondaryColor = colors[1]?.trim()
                root.tertiaryColor  = colors[2]?.trim()
                myCanvas.requestPaint()
            }
        }
    }

    Item {
        id: myRect
        anchors.fill: parent

        MaterialSymbol {
            anchors.centerIn: parent
            text: "hourglass_bottom"
            color: Appearance.colors.colPrimary
            iconSize: Appearance.font.pixelSize.hugeass
        }

        Canvas {
            id: myCanvas
            anchors {
                centerIn: parent
                margins: 8
            }    
            implicitWidth: root.implicitHeight - 16
            implicitHeight: root.implicitHeight - 16
            
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d");
                var centerX = width / 2;
                var centerY = height / 2;
                var radius = width / 2;

                ctx.reset();
                ctx.beginPath();
                ctx.fillStyle = root.primaryColor;
                ctx.moveTo(centerX, centerY);
                
                ctx.arc(centerX, centerY, radius, Math.PI, 0, false);
                ctx.closePath();
                ctx.fill();

                ctx.beginPath();
                ctx.fillStyle = root.secondaryColor;
                ctx.moveTo(centerX, centerY);
                ctx.arc(centerX, centerY, radius, 0, Math.PI / 2, false);
                ctx.closePath();
                ctx.fill();

                ctx.beginPath();
                ctx.fillStyle = root.tertiaryColor;
                ctx.moveTo(centerX, centerY);
                ctx.arc(centerX, centerY, radius, Math.PI / 2, Math.PI, false);
                ctx.closePath();
                ctx.fill();
            }
        }

    }

}