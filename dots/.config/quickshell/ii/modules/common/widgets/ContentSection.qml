import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ColumnLayout {
    id: root
    property string title
    property string icon: ""
    property list<string> keywords: []
    default property alias data: sectionContent.data

    Layout.fillWidth: true
    spacing: 6

    Component.onCompleted: {
        if (page.register == false) return
        SearchRegistry.registerSection({
            pageIndex: page.index,
            title: root.title,
            keywords: root.keywords,
            yPos: root.y
        })
    }

    RowLayout {
        spacing: 6
        OptionalMaterialSymbol {
            icon: root.icon
            iconSize: Appearance.font.pixelSize.hugeass
        }
        StyledText {
            text: root.title
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.Medium
            color: Appearance.colors.colOnSecondaryContainer
        }
    }

    ColumnLayout {
        id: sectionContent
        Layout.fillWidth: true
        spacing: 4

    }
}
