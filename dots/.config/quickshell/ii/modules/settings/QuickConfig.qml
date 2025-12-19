import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    forceWidth: true

    Process {
        id: randomWallProc
        property string status: ""
        property string scriptPath: `${Directories.scriptPath}/colors/random/random_konachan_wall.sh`
        command: ["bash", "-c", FileUtils.trimFileProtocol(randomWallProc.scriptPath)]
        stdout: SplitParser {
            onRead: data => {
                randomWallProc.status = data.trim();
            }
        }
    }

    component SmallLightDarkPreferenceButton: RippleButton {
        id: smallLightDarkPreferenceButton
        required property bool dark
        property color colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
        padding: 5
        Layout.fillWidth: true
        toggled: Appearance.m3colors.darkmode === dark
        colBackground: Appearance.colors.colLayer2
        onClicked: {
            Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`]);
        }
        contentItem: Item {
            anchors.centerIn: parent
            RowLayout {
                anchors.centerIn: parent
                spacing: 10
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    iconSize: 30
                    text: dark ? "dark_mode" : "light_mode"
                    fill: toggled ? 1 : 0
                    color: smallLightDarkPreferenceButton.colText
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: dark ? Translation.tr("Dark") : Translation.tr("Light")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: smallLightDarkPreferenceButton.colText
                }
            }
        }
    }

    // Wallpaper selection
    ContentSection {
        icon: "format_paint"
        title: Translation.tr("Wallpaper & Colors")
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true

            Item {
                implicitWidth: 340
                implicitHeight: 200
                
                StyledImage {
                    id: wallpaperPreview
                    anchors.fill: parent
                    sourceSize.width: parent.implicitWidth
                    sourceSize.height: parent.implicitHeight
                    fillMode: Image.PreserveAspectCrop
                    source: Config.options.background.wallpaperPath
                    cache: false
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: 360
                            height: 200
                            radius: Appearance.rounding.normal
                        }
                    }
                    RippleButton {
                        anchors.fill: parent
                        colBackground: "transparent"
                        colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnPrimary, 0.85)
                        colRipple: ColorUtils.transparentize(Appearance.colors.colOnPrimary, 0.5)
                        onClicked: {
                            Quickshell.execDetached(`${Directories.wallpaperSwitchScriptPath}`);
                        }
                    }
                    
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "hourglass_top"
                    color: Appearance.colors.colPrimary
                    iconSize: 40
                    z: -1
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        margins: 10
                    }

                    implicitWidth: Math.min(text.implicitWidth + 20, parent.width - 20)
                    implicitHeight: text.implicitHeight + 5
                    color: Appearance.colors.colPrimary
                    radius: Appearance.rounding.full

                    StyledText {
                        id: text
                        anchors.centerIn: parent
                        property string fileName: Config.options.background.wallpaperPath.split("/")[Config.options.background.wallpaperPath.split("/").length - 1]
                        text: fileName.length > 30 ? fileName.slice(27) + "..." : fileName
                        color: Appearance.colors.colOnPrimary
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    uniformCellSizes: true

                    SmallLightDarkPreferenceButton {
                        Layout.preferredHeight: 60
                        dark: false
                    }
                    SmallLightDarkPreferenceButton {
                        Layout.preferredHeight: 60
                        dark: true
                    }
                }
                
                StyledFlickable {
                    id: flickable
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    contentHeight: contentLayout.implicitHeight
                    contentWidth: width
                    clip: true

                    ColumnLayout {
                        id: contentLayout
                        width: flickable.width
                        RowLayout {
                            ColorPreviewButton {
                                colorScheme: "auto"
                                StyledToolTip {
                                    text: Translation.tr("Auto")
                                }
                            }
                            ColorPreviewButton {
                                colorScheme: "scheme-content"
                                StyledToolTip {
                                    text: Translation.tr("Content")
                                }
                            }
                            ColorPreviewButton {
                                colorScheme: "scheme-expressive"
                                StyledToolTip {
                                    text: Translation.tr("Expressive")
                                }
                            }
                        }
                        RowLayout {
                            ColorPreviewButton {
                                colorScheme: "scheme-fidelity"
                                StyledToolTip {
                                    text: Translation.tr("Fidelity")
                                }
                            }
                            ColorPreviewButton {
                                colorScheme: "scheme-fruit-salad"
                                StyledToolTip {
                                    text: Translation.tr("Fruit Salad")
                                }
                            }
                            ColorPreviewButton {
                                colorScheme: "scheme-monochrome"
                                StyledToolTip {
                                    text: Translation.tr("Monochrome")
                                }
                            }
                        }
                        RowLayout {
                            ColorPreviewButton {
                                colorScheme: "scheme-neutral"
                                StyledToolTip {
                                    text: Translation.tr("Neutral")
                                }
                            }
                            ColorPreviewButton {
                                colorScheme: "scheme-rainbow"
                                StyledToolTip {
                                    text: Translation.tr("Rainbow")
                                }
                            }
                            ColorPreviewButton {
                                colorScheme: "scheme-tonal-spot"
                                StyledToolTip {
                                    text: Translation.tr("Tonal Spot")
                                }
                            }
                        }
                    
                    }
                }
            }
        }

    
        ConfigRow {
            uniform: true
            Layout.fillWidth: true
            
            RippleButtonWithIcon {
                enabled: !randomWallProc.running
                visible: Config.options.policies.weeb === 1
                Layout.fillWidth: true
                buttonRadius: Appearance.rounding.small
                materialIcon: "ifl"
                mainText: randomWallProc.running ? Translation.tr("Be patient...") : Translation.tr("Random: Konachan")
                onClicked: {
                    randomWallProc.scriptPath = `${Directories.scriptPath}/colors/random/random_konachan_wall.sh`;
                    randomWallProc.running = true;
                }
                StyledToolTip {
                    text: Translation.tr("Random SFW Anime wallpaper from Konachan\nImage is saved to ~/Pictures/Wallpapers")
                }
            }
            RippleButtonWithIcon {
                enabled: !randomWallProc.running
                visible: Config.options.policies.weeb === 1
                Layout.fillWidth: true
                buttonRadius: Appearance.rounding.small
                materialIcon: "ifl"
                mainText: randomWallProc.running ? Translation.tr("Be patient...") : Translation.tr("Random: osu! seasonal")
                onClicked: {
                    randomWallProc.scriptPath = `${Directories.scriptPath}/colors/random/random_osu_wall.sh`;
                    randomWallProc.running = true;
                }
                StyledToolTip {
                    text: Translation.tr("Random osu! seasonal background\nImage is saved to ~/Pictures/Wallpapers")
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "ev_shadow"
            text: Translation.tr("Transparency")
            checked: Config.options.appearance.transparency.enable
            onCheckedChanged: {
                Config.options.appearance.transparency.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Might look ass. Unsupported.")
            }
        }
    }

    

    ContentSection {
        icon: "screenshot_monitor"
        title: Translation.tr("Bar & screen")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Top"),
                            icon: "arrow_upward",
                            value: 0 // bottom: false, vertical: false
                        },
                        {
                            displayName: Translation.tr("Left"),
                            icon: "arrow_back",
                            value: 2 // bottom: false, vertical: true
                        },
                        {
                            displayName: Translation.tr("Bottom"),
                            icon: "arrow_downward",
                            value: 1 // bottom: true, vertical: false
                        },
                        {
                            displayName: Translation.tr("Right"),
                            icon: "arrow_forward",
                            value: 3 // bottom: true, vertical: true
                        }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Bar style")

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Hug"),
                            icon: "line_curve",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Float"),
                            icon: "page_header",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "toolbar",
                            value: 2
                        }
                    ]
                }
            }
        }

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Screen round corner")

                ConfigSelectionArray {
                    currentValue: Config.options.appearance.fakeScreenRounding
                    onSelected: newValue => {
                        Config.options.appearance.fakeScreenRounding = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("When not fullscreen"),
                            icon: "fullscreen_exit",
                            value: 2
                        }
                    ]
                }
            }
            
        }
    }

    NoticeBox {
        Layout.fillWidth: true
        text: Translation.tr('Not all options are available in this app. You should also check the config file by hitting the "Config file" button on the topleft corner or opening %1 manually.').arg(Directories.shellConfigPath)

        Item {
            Layout.fillWidth: true
        }
        RippleButtonWithIcon {
            id: copyPathButton
            property bool justCopied: false
            Layout.fillWidth: false
            buttonRadius: Appearance.rounding.small
            materialIcon: justCopied ? "check" : "content_copy"
            mainText: justCopied ? Translation.tr("Path copied") : Translation.tr("Copy path")
            onClicked: {
                copyPathButton.justCopied = true
                Quickshell.clipboardText = FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse/config.json`);
                revertTextTimer.restart();
            }
            colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
            colBackgroundHover: Appearance.colors.colPrimaryContainerHover
            colRipple: Appearance.colors.colPrimaryContainerActive

            Timer {
                id: revertTextTimer
                interval: 1500
                onTriggered: {
                    copyPathButton.justCopied = false
                }
            }
        }
    }
}
