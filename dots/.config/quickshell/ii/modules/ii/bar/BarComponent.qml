import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: rootItem

    property var list
    required property var modelData
    required property int index

    implicitWidth: wrapper.implicitWidth

    property var compMap: ({
        "workspaces": workspaceComp,
        "music_player": musicPlayerComp,
        "system_monitor": systemMonitorComp,
        "clock": clockComp,
        "battery": batteryComp,
        "utility_buttons": utilityButtonsComp
    })

    BarGroup {
        id: wrapper
        anchors.verticalCenter: rootItem.verticalCenter
        startRadius: index == 0 || list.length == 1 ? Appearance.rounding.full : Appearance.rounding.verysmall
        endRadius: index == list.length - 1 || list.length == 1 ? Appearance.rounding.full : Appearance.rounding.verysmall
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
        Media {}
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
            showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
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