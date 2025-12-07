import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: rootItem

    property int barSection // 0: left, 1: center, 2: right
    property var list
    required property var modelData
    required property int index
    property var originalIndex: index



    implicitWidth: wrapper.implicitWidth

    property var compMap: ({
        "workspaces": workspaceComp,
        "music_player": musicPlayerComp,
        "system_monitor": systemMonitorComp,
        "clock": clockComp,
        "battery": batteryComp,
        "utility_buttons": utilityButtonsComp,
        "system_tray": systemTrayComp
    })

    BarGroup {
        id: wrapper
        anchors.verticalCenter: rootItem.verticalCenter
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
            sourceComponent: compMap[modelData.id]
        }
    }
    
    
    Component {
        id: systemMonitorComp
        Resources {
            alwaysShowAllResources: true
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
        id: clockComp
        ClockWidget {
            implicitWidth: 200 //!FIXME
            showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
        }
    }
    Component {
        id: systemTrayComp
        SysTray {
            invertSide: Config?.options.bar.bottom
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