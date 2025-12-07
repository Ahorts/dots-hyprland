pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml.Models

import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    Layout.fillWidth: true
    
    // short version of -> height: listModel.length * 40 + (listModel.length - 1) * 4 + listModel.length * 4 + 20 (component height + space between them + component margin + listView padding)
    implicitHeight: listModel.length * 48 + componentSelector.height + 16 + 6

    color: Appearance.colors.colLayer2
    radius: Appearance.rounding.large

    property var listModel
    property int selectedCompIndex

    signal updated(var newList)

    DelegateModel {
        id: visualModel

        model: {
            values: root.listModel
        }
        delegate: ConfigListViewEntry {}
    }

    StyledListView {
        id: view

        interactive: false
        anchors {
            fill: parent
            margins: 10
        }

        add: null

        model: visualModel

        spacing: 4
        cacheBuffer: 50
        
    }
    
    RowLayout {
        id: componentSelectRow
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 10
        }

        StyledComboBox {
            id: componentSelector
            
            buttonIcon: "box"
            textRole: "title"
            model: Config.options.bar.layouts.dynamicComps
            enabled: Config.options.bar.layouts.dynamicComps.length >= 1

            onActivated: index => {
                root.selectedCompIndex = index;
            }
        }

        RippleButton {
            id: addComponentButton
            implicitHeight: componentSelector.implicitHeight
            //buttonRadius: Appearance.rounding.full // Maybe?
            buttonText: Translation.tr("Add component")

            enabled: Config.options.bar.layouts.dynamicComps.length >= 1

            colBackground: Appearance.colors.colSecondaryContainer
            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
            rippleColor: Appearance.colors.colSecondaryContainerActive
            
            onClicked: {
                listModel.push(Config.options.bar.layouts.dynamicComps[root.selectedCompIndex]);
                Config.options.bar.layouts.dynamicComps.splice(root.selectedCompIndex, 1);
                root.updated(listModel);
            }
        }
    }
    
    
} 