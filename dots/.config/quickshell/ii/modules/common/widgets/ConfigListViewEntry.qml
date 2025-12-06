import QtQuick
import QtQuick.Layouts

import qs.modules.common
import qs.modules.common.widgets

MouseArea {
    id: dragArea
    
    required property var modelData

    property bool held: false

    anchors {
        left: parent?.left
        right: parent?.right
    }
    height: content.height

    pressAndHoldInterval: 200
    drag.target: held ? content : undefined
    drag.axis: Drag.YAxis

    onPressAndHold: held = true
    onReleased: held = false

    Rectangle {
        id: content

        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }
        width: dragArea.width
        height: column.implicitHeight + 4

        border.width: 1
        border.color: "lightsteelblue"

        color: dragArea.held ? "lightsteelblue" : "white"
        Behavior on color { ColorAnimation { duration: 100 } }

        radius: 2

        Drag.active: dragArea.held
        Drag.source: dragArea
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        states: State {
            when: dragArea.held

            ParentChange {
                target: content
                parent: root
            }
            AnchorChanges {
                target: content
                anchors {
                    horizontalCenter: undefined
                    verticalCenter: undefined
                }
            }
        }

        Column { // Content
            id: column
            anchors {
                fill: parent
                margins: 2
            }

            Text { text: qsTr('Name: ') + modelData.test }
            Text { text: qsTr('Type: ') + modelData.test }
            Text { text: qsTr('Age: ') + modelData.test }
            Text { text: qsTr('Size: ') + modelData.test }
        }

    }

    DropArea {
        anchors {
            fill: parent
            margins: 10
        }

        onEntered: (drag) => {
            visualModel.items.move(
                    drag.source.DelegateModel.itemsIndex,
                    dragArea.DelegateModel.itemsIndex)
        }
    }
}
    