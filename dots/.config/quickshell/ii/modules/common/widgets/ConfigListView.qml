pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml.Models

import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    Layout.fillWidth: true
    height: 400

    DelegateModel {
        id: visualModel

        model: {
            values: [
                {test: "test"}, {test: "test2"}, {test: "test3"}, {test: "test4"}, {test: "test5"},
            ]
        }
        delegate: ConfigListViewEntry {}
    }

    ListView {
        id: view

        anchors {
            fill: parent
            margins: 2
        }

        model: visualModel

        spacing: 4
        cacheBuffer: 50
    }
//![4]
//![5]
} 