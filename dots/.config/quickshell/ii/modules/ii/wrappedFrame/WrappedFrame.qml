import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: wrappedFrame

    property int frameThickness: Config.options.appearance.wrappedFrameThickness
    property bool barVertical: Config.options.bar.vertical
    property bool barBottom: Config.options.bar.bottom

    component HorizontalFrame: PanelWindow {
        id: cornerPanelWindow

        color: Appearance.colors.colLayer0
        implicitWidth: frameThickness;implicitHeight: frameThickness

        anchors {
            left: true
            right: true
        }
    }

    component VerticalFrame: PanelWindow {
        id: cornerPanelWindow

        color: Appearance.colors.colLayer0
        implicitWidth: frameThickness;implicitHeight: frameThickness

        anchors {
            bottom: true
            top: true
        }
    }

    component ScreenCorner: PanelWindow {
        id: screenCornerWindow
        property bool left
        property bool bottom
        screen: monitorScope.modelData
        anchors {
            bottom: bottom
            top: !bottom
            left: left
            right: !left
        }
        implicitHeight: Appearance.rounding.screenRounding
        implicitWidth: Appearance.rounding.screenRounding
        color: "transparent"
            
        RoundCorner {
            id: leftCorner
            anchors {
                top: !bottom ? parent.top : undefined
                bottom: bottom ? parent.bottom : undefined
                left: left ? parent.left : undefined
                right: !left ? parent.right : undefined
            }

            implicitSize: Appearance.rounding.screenRounding
            color: Appearance.colors.colLayer0 // // add option for showbarbackground

            corner: screenCornerWindow.left ? 
                (screenCornerWindow.bottom ? RoundCorner.CornerEnum.BottomLeft : RoundCorner.CornerEnum.TopLeft) :
                (screenCornerWindow.bottom ? RoundCorner.CornerEnum.BottomRight : RoundCorner.CornerEnum.TopRight)
        }
    }

    Loader {
        active: Config.options.appearance.fakeScreenRounding == 3
        sourceComponent: Variants {
            model: Quickshell.screens

            Scope {
                id: monitorScope
                required property var modelData

                // SCREEN CORNERS
                Loader {
                    active: !(barBottom && !barVertical) && !(barVertical && !barBottom)
                    sourceComponent: ScreenCorner {
                        left: true
                        bottom: true
                    }
                }
                Loader {
                    active: barBottom
                    sourceComponent: ScreenCorner {
                        left: true
                        bottom: false
                    }
                }
                Loader {
                    active: !(!barBottom && !barVertical) && !(barVertical && barBottom)
                    sourceComponent: ScreenCorner {
                        left: false
                        bottom: false
                    }
                }
                Loader {
                    active:  !barBottom
                    sourceComponent: ScreenCorner {
                        left: false
                        bottom: true
                    }
                }

                // FRAMES

                Loader {
                    active: !(!barVertical && barBottom)
                    sourceComponent: HorizontalFrame {
                        screen: monitorScope.modelData
                        anchors.bottom: true
                    }
                }
                Loader {
                    active: !(!barVertical && !barBottom)
                    sourceComponent: HorizontalFrame {
                        screen: monitorScope.modelData
                        anchors.top: true
                    }
                }
                Loader {
                    active: !(barVertical && barBottom)
                    sourceComponent: VerticalFrame {
                        screen: monitorScope.modelData
                        anchors.right: true
                    }
                }
                Loader {
                    active: !(barVertical && !barBottom)
                    sourceComponent: VerticalFrame {
                        screen: monitorScope.modelData
                        anchors.left: true
                    }
                }
            }
        }
    }
}