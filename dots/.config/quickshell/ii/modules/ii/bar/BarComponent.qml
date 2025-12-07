import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.modules.ii.verticalBar as Vertical

Item {
    id: rootItem

    property int barSection // 0: left, 1: center, 2: right
    property var list
    required property var modelData
    required property int index
    property var originalIndex: index
    property bool vertical: false

    implicitWidth: wrapper.implicitWidth
    implicitHeight: wrapper.implicitHeight

    property var compMap: ({
        "workspaces": workspaceComp,
        "music_player": musicPlayerComp,
        "system_monitor": systemMonitorComp,
        "clock": clockComp,
        "battery": batteryComp,
        "utility_buttons": utilityButtonsComp,
        "system_tray": systemTrayComp,
        "active_window": activeWindowComp
    })

    property var verticalCompMap: ({
        "workspaces": workspaceCompVert,
        "music_player": musicPlayerCompVert,
        "system_monitor": systemMonitorCompVert,
        "clock": clockCompVert,
        "battery": batteryCompVert,
        "utility_buttons": utilityButtonsComp,
        "system_tray": systemTrayCompVert,
        "date": dateCompVert,
        "active_window": activeWindowCompVert
    })

    BarGroup {
        id: wrapper
        anchors {
            verticalCenter: root.vertical ? rootItem.verticalCenter : undefined
            horizontalCenter: root.vertical ? undefined : rootItem.horizontalCenter
        }
        
        vertical: rootItem.vertical
        startRadius: {
            const isFirst = originalIndex === 0
            const isSingle = list.length === 1

            if (barSection == 0 && isFirst) // special case: first item in left section
                return Appearance.rounding.verysmall
            
            if (isFirst || isSingle)
                return Appearance.rounding.full

            return Appearance.rounding.verysmall
        }
        endRadius: {
            const isLast = originalIndex === list.length - 1
            const isSingle = list.length === 1

            if (barSection == 2 && isLast) // special case: last item in right section
                return Appearance.rounding.verysmall

            if (isLast || isSingle)
                return Appearance.rounding.full

            return Appearance.rounding.verysmall
        }
        items: Loader {
            id: loader
            active: true
            sourceComponent: vertical ? verticalCompMap[modelData.id] : compMap[modelData.id]
        }
    }
    
    Component {
        id: activeWindowCompVert
         ActiveWindow {
            vertical: true
        }
    }
    Component {
        id: activeWindowComp
         ActiveWindow {
            visible: root.useShortenedForm === 0
            Layout.rightMargin: Appearance.rounding.screenRounding
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
    Component {
        id: systemMonitorComp
        Resources {
            alwaysShowAllResources: true //FIXME
        }
    }
    Component {
        id: systemMonitorCompVert
        Vertical.Resources {
            Layout.fillWidth: true
            Layout.fillHeight: false
        }
    }
    Component {
        id: musicPlayerCompVert
        Vertical.VerticalMedia {
            Layout.fillWidth: true
            Layout.fillHeight: false
        }
    }
    Component {
        id: musicPlayerComp
        Media {
            implicitWidth: 250 // Add an config option maybe?
        }
    }
    Component {
        id: utilityButtonsComp
        UtilButtons {
            visible: (Config.options.bar.verbose && root.useShortenedForm === 0)
            Layout.alignment: Qt.AlignVCenter
        }
    }
    Component {
        id: batteryComp
        BatteryIndicator {
            visible: (root.useShortenedForm < 2 && Battery.available)
            Layout.alignment: Qt.AlignVCenter
        }
    }
    Component {
        id: batteryCompVert
        Vertical.BatteryIndicator {
            visible: Battery.available
            Layout.fillWidth: true
            Layout.fillHeight: false
        }
    }
    Component {
        id: dateCompVert
        Vertical.VerticalDateWidget {
            Layout.fillWidth: true
            Layout.fillHeight: false
        }
    }
    Component {
        id: clockCompVert
        Vertical.VerticalClockWidget {
            Layout.fillWidth: true
            Layout.fillHeight: false
        }
    }
    Component {
        id: clockComp
        ClockWidget {
            implicitWidth: 200 //!FIXME
            showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
        }
    }
    Component {
        id: systemTrayCompVert
        SysTray {
            vertical: true
            invertSide: Config?.options.bar.bottom
        }
    }
    Component {
        id: systemTrayComp
        SysTray {
            invertSide: Config?.options.bar.bottom
        }
    }
    Component {
        id: workspaceCompVert
        Workspaces {
            vertical: true
            MouseArea {
                // Right-click to toggle overview
                anchors.fill: parent
                acceptedButtons: Qt.RightButton

                onPressed: event => {
                    if (event.button === Qt.RightButton) {
                        GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                    }
                }
            }
        }
    }
    Component {
        id: workspaceComp
        Workspaces {
            Layout.fillHeight: true
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton

                onPressed: event => {
                    if (event.button === Qt.RightButton) {
                        GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                    }
                }
            }
        } 
    }
    
}