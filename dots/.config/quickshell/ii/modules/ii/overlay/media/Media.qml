pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.mediaControls
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    minimumWidth: 400
    minimumHeight: 400

    contentItem: OverlayBackground {
        id: contentItem
        radius: root.contentRadius
        property real padding: 8
        
    }
}