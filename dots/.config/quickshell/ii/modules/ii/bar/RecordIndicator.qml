import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell


Item {
    id: indicator
    property bool activelyRecording: Persistent.states.screenRecord.active

    property color colBackground: Appearance.colors.colPrimary
    property color colText: Appearance.colors.colOnPrimary

    implicitWidth: 80 // we have to enter a fixed size to make it dull 

    Component.onCompleted: rootItem.toggleVisible(activelyRecording)
    onActivelyRecordingChanged: rootItem.toggleVisible(activelyRecording)

    RippleButton {
        anchors.centerIn: parent
        implicitWidth: parent.implicitWidth
        implicitHeight: 20
        colBackgroundHover: "transparent"
        colRipple: indicator.colText
        
        onClicked: {
            Quickshell.execDetached(Directories.recordScriptPath)
        }
    }


    RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: 4

        MaterialSymbol {
            Layout.bottomMargin: 2
            id: iconIndicator
            z: 1
            text: "screen_record"
            color: indicator.colText
        }
        
        StyledText {
            id: textIndicator
            property int seconds: 0
            Layout.topMargin: 2

            function formatTime(totalSeconds) {
                let mins = Math.floor(totalSeconds / 60);
                let secs = totalSeconds % 60;
                return String(mins).padStart(2, '0') + ":" + String(secs).padStart(2, '0');
            }

            text: formatTime(seconds)
            color: indicator.colText
            Timer {
                interval: 1000
                running: indicator.activelyRecording
                repeat: true
                onTriggered: textIndicator.seconds ++
            }
        }
    }
    
}