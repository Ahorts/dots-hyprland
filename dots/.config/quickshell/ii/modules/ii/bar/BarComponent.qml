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
    visible: modelData.visible ?? true

    function toggleVisible(visible) {
        if (barSection == 0) Config.options.bar.layouts.left[originalIndex].visible = visible
        else if (barSection == 1) Config.options.bar.layouts.center[originalIndex].visible = visible
        else if (barSection == 2) Config.options.bar.layouts.right[originalIndex].visible = visible
    }

    property var compMap: ({ // [horizontal, vertical]
        "workspaces": [workspaceComp,workspaceComp],
        "music_player": [musicPlayerComp, musicPlayerCompVert],
        "system_monitor": [systemMonitorComp, systemMonitorCompVert],
        "clock": [clockComp, clockCompVert],
        "battery": [batteryComp, batteryCompVert],
        "utility_buttons": [utilityButtonsComp, utilityButtonsCompVert],
        "system_tray": [systemTrayComp, systemTrayCompVert],
        "active_window": [activeWindowComp, activeWindowCompVert],
        "date": [dateCompVert, dateCompVert],
        "record_indicator": [recordIndicatorComp, recordIndicatorComp],
    })

    property real startRadius: {
        if (list.length === 1 || (barSection !== 2 && originalIndex === 0))
            return Appearance.rounding.full

        if (list.length > 1) {
            let firstVisible = list.find(item => item.visible !== false)
            if (firstVisible && list.indexOf(firstVisible) === originalIndex) {
                return Appearance.rounding.full
            }
        }
        return Appearance.rounding.verysmall
    }

    property real endRadius: {
        if (list.length === 1 || (barSection !== 2 && originalIndex === list.length - 1)) 
            return Appearance.rounding.full

        if (list.length > 1) {
            let lastVisible = list.slice().reverse().find(item => item.visible !== false)
            if (lastVisible && list.indexOf(lastVisible) === originalIndex) {
                return Appearance.rounding.full
            }
        }
        return Appearance.rounding.verysmall
    }

    BarGroup {
        id: wrapper
        vertical: rootItem.vertical
        anchors {
            verticalCenter: root.vertical ? rootItem.verticalCenter : undefined
            horizontalCenter: root.vertical ? undefined : rootItem.horizontalCenter
        }
        
        startRadius: rootItem.startRadius
        endRadius: rootItem.endRadius
        colBackground: itemLoader.item.colBackground ?? Appearance.colors.colLayer2

        items: Loader {
            id: itemLoader
            active: true
            sourceComponent: compMap[modelData.id][vertical ? 1 : 0]
        }
    }
    
    Component { id: recordIndicatorComp; RecordIndicator {} }

    Component { id: activeWindowCompVert; ActiveWindow { vertical: true } }
    Component { id: activeWindowComp; ActiveWindow {} }

    Component { id: systemMonitorComp; Resources {} }
    Component { id: systemMonitorCompVert; Vertical.Resources {} }

    Component { id: musicPlayerCompVert; Vertical.VerticalMedia {} }
    Component { id: musicPlayerComp; Media {} }

    Component { id: utilityButtonsCompVert; UtilButtons { vertical: true } }
    Component { id: utilityButtonsComp; UtilButtons {} }

    Component { id: batteryComp; BatteryIndicator {} }
    Component { id: batteryCompVert; Vertical.BatteryIndicator {} }

    Component { id: clockCompVert; Vertical.VerticalClockWidget {} }
    Component { id: clockComp; ClockWidget {} }

    Component { id: systemTrayCompVert; SysTray { vertical: true } }
    Component { id: systemTrayComp; SysTray {} }

    Component { id: dateCompVert; Vertical.VerticalDateWidget {} }

    Component {
        id: workspaceComp
        Workspaces {
            vertical: rootItem.vertical
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