pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    property bool hyprscrollingEnabled: Config.options.overview.hyprscrollingImplementation.enable
    property int maxWorkspaceWidth: Config.options.overview.hyprscrollingImplementation.maxWorkspaceWidth
    required property var panelWindow
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
    readonly property int rows: 10
    readonly property int columns: 1
    readonly property int workspacesShown: root.rows * root.columns

    readonly property bool useWorkspaceMap: Config.options.overview.useWorkspaceMap
    readonly property list<int> workspaceMap: Config.options.overview.workspaceMap
    property int monitorIndex // to be set by parent
    property int workspaceOffset: useWorkspaceMap ? workspaceMap[monitorIndex] : 0
    
    readonly property int workspaceGroup: Math.floor((monitor.activeWorkspace?.id - workspaceOffset - 1) / workspacesShown)
    property bool monitorIsFocused: (Hyprland.focusedMonitor?.name == monitor.name)
    property var windows: HyprlandData.windowList
    property var windowByAddress: HyprlandData.windowByAddress
    property var monitorData: HyprlandData.monitors.find(m => m.id === root.monitor?.id)
    property real scaleRatio: 0.25 // to be changed later
    property color activeBorderColor: Appearance.colors.colSecondary

    property real workspaceImplicitWidth: (monitorData?.transform % 2 === 1) ? 
        ((monitor.height - monitorData?.reserved[0] - monitorData?.reserved[2]) * root.scaleRatio / monitor.scale) :
        ((monitor.width - monitorData?.reserved[0] - monitorData?.reserved[2]) * root.scaleRatio / monitor.scale)
    property real workspaceImplicitHeight: (monitorData?.transform % 2 === 1) ? 
        ((monitor.width - monitorData?.reserved[1] - monitorData?.reserved[3]) * root.scaleRatio / monitor.scale) :
        ((monitor.height - monitorData?.reserved[1] - monitorData?.reserved[3]) * root.scaleRatio / monitor.scale)

    // we are using a width map to get all windows width and settings workspaceImplicitWidth to the maximum item of this list/map
    property list<int> widthMap: [] 

    property int windowRounding: Appearance.rounding.normal

    property int workspaceZ: 0
    property int windowZ: 1
    property int windowDraggingZ: 99999
    property real workspaceSpacing: 10

    property int dragDropType: -1 // 0: workspace, 1: window
    
    property string draggingFromWindowAddress
    property string draggingTargetWindowAdress
    property string draggingDirection  // options: 'l' or 'r' // only for window dragging

    property bool draggingWindowsFloating

    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1

    implicitWidth: monitor.width 
    implicitHeight: monitor.height


    property var activeWindow: windows.find(w =>
        w.focusHistoryID === 0 &&
        w.workspace?.id === monitor.activeWorkspace?.id &&
        w.monitor === monitor.id
    )

    property var activeWindowData
    
    function getWsRow(ws) {
        var wsAdjusted = ws - root.workspaceOffset
        var normalRow = Math.floor((wsAdjusted - 1) / root.columns) % root.rows;
        return (Config.options.overview.orderBottomUp ? root.rows - normalRow - 1 : normalRow);
    }

    function getWsColumn(ws) {
        var wsAdjusted = ws - root.workspaceOffset
        var normalCol = (wsAdjusted - 1) % root.columns;
        return (Config.options.overview.orderRightLeft ? root.columns - normalCol - 1 : normalCol);
    }

    function getWsInCell(ri, ci) {
        var wsInCell = (Config.options.overview.orderBottomUp ? root.rows - ri - 1 : ri) 
                    * root.columns 
                    + (Config.options.overview.orderRightLeft ? root.columns - ci - 1 : ci) 
                    + 1
        return wsInCell + root.workspaceOffset
    }

    property int currentWorkspace: monitor.activeWorkspace?.id - root.workspaceOffset
    property int scrollWorkspace: 0

    onCurrentWorkspaceChanged: {
        scrollWorkspace = currentWorkspace - 1
        scrollY = (scrollWorkspace - 1) * workspaceImplicitHeight // actually we dont have to decrease 1 here, but I want active workspace row to be in center of the screen
    }

    property real initScale: 1.08 //TODO: add config option
    scale: initScale
    Behavior on scale {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    Component.onCompleted: {
        scrollWorkspace = currentWorkspace - 1
        scrollY = (scrollWorkspace - 1) * workspaceImplicitHeight
        HyprlandData.windowListChanged() // making sure it reloads
        scale = 1
    }

    onScrollWorkspaceChanged: {
        scrollY = (scrollWorkspace - 1) * workspaceImplicitHeight // same as line114
    }

    property real scrollY: 0
    property var focusedXPerWorkspace: []
    property var lastFocusedPerWorkspace: []

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0) { // up
                if (root.scrollWorkspace === 0) return
                root.scrollWorkspace -= 1
            } else { // down
                if (root.scrollWorkspace === root.workspacesShown - 1) return
                root.scrollWorkspace += 1
            }
            // console.log(JSON.stringify(root.lastFocusedPerWorkspace[0])) // debug
        }
    }

    onWindowsChanged: {
        lastFocusedPerWorkspace = []; focusedXPerWorkspace = [];
        
        const startWs = root.workspaceOffset + 1;
        const endWs = root.workspaceOffset + 10;

        for (var ws = startWs; ws <= endWs; ws++) {
            var windowsInWS = root.windows.filter(function(w) {
                return w.workspace.id === ws && w.monitor === root.monitor.id;
            });

            if (windowsInWS.length === 0) {
                lastFocusedPerWorkspace.push(null);
                focusedXPerWorkspace.push(null);
            } else {
                var lastFocused = windowsInWS.reduce(function(a, b) {
                    return (a.focusHistoryID < b.focusHistoryID) ? a : b;
                });
                lastFocusedPerWorkspace.push(lastFocused);
                
                var monitorX = (root.monitor?.x ?? 0);
                var monitorReservedX = (root.monitorData?.reserved?.[0] ?? 0);
                var localX = (lastFocused.at[0] - monitorX - monitorReservedX) * root.scaleRatio;
                
                focusedXPerWorkspace.push(localX);
            }
        }
    }

    Rectangle { // Background
        id: overviewBackground
        anchors.fill: parent
        color: "transparent"
        Component.onCompleted: color = ColorUtils.transparentize("black", 0.5)
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        StyledFlickable { // using just a hack to make it work, not actually using flickable for core
            id: windowSpace
            anchors.horizontalCenter: parent.horizontalCenter
            contentWidth: parent.implicitWidth
            contentHeight: parent.implicitHeight
            contentY: root.scrollY

            Repeater {
                model: root.workspacesShown
                delegate: Rectangle {
                    required property int index
                    property int wsId: index + 1 + root.workspaceOffset
                    property int rowIndex: getWsRow(wsId)
                    property int colIndex: getWsColumn(wsId)
                    property bool hovering: false
                    anchors.horizontalCenter: parent.horizontalCenter

                    y: (root.workspaceImplicitHeight + root.workspaceSpacing) * rowIndex
                    implicitWidth: root.workspaceImplicitWidth
                    implicitHeight: root.workspaceImplicitHeight
                    color: hovering ? ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 0.7) : ColorUtils.transparentize(Appearance.colors.colLayer1, 0.5)
                    radius: root.windowRounding

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    StyledText {
                        text: wsId
                        anchors.centerIn: parent
                        font.pixelSize: 64
                        color: ColorUtils.transparentize(Appearance.colors.colSecondaryContainer,0.5)
                        opacity: 0.0  // text flashes over windowses for a split second if we dont put this animation
                        Component.onCompleted: opacity = 1
                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }
                    
                    DropArea { // Workspace drop
                        anchors.fill: parent
                        onEntered: {
                            root.dragDropType = 0
                            root.draggingTargetWorkspace = wsId
                            hovering = true
                        }
                        onExited: {
                            root.dragDropType = -1
                            if (root.draggingTargetWorkspace == wsId) root.draggingTargetWorkspace = -1
                            hovering = false
                        }
                    }

                }
            }


            Repeater { // Window repeater
                id: windowRepeater
                model: ScriptModel {
                    values: {
                        return ToplevelManager.toplevels.values.filter((toplevel) => {
                            const address = `0x${toplevel.HyprlandToplevel?.address}`
                            const win = windowByAddress[address]
                            if (!win) return false

                            const inWorkspaceGroup =
                                (root.workspaceGroup * root.workspacesShown + root.workspaceOffset <
                                win.workspace?.id &&
                                win.workspace?.id <=
                                (root.workspaceGroup + 1) * root.workspacesShown + root.workspaceOffset)

                            return inWorkspaceGroup
                        })
                    }
                }
                delegate: OverviewWindow {
                    id: window
                    required property int index
                    required property var modelData
                    property int monitorId: windowData?.monitor
                    property var monitor: HyprlandData.monitors.find(m => m.id == monitorId)
                    property var address: `0x${modelData.HyprlandToplevel.address}`
                    windowRounding: root.windowRounding
                    toplevel: modelData
                    monitorData: this.monitor
                    scale: root.scaleRatio
                    widgetMonitor: HyprlandData.monitors.find(m => m.id == root.monitor.id) // used by overview window
                    windowData: windowByAddress[address]

                    property int wsId: windowData?.workspace?.id

                    property var wsWindowsSorted: {
                        const arr = []
                        const all = windowRepeater.model.values

                        for (let i = 0; i < all.length; i++) {
                            const t = all[i]
                            const addr = `0x${t.HyprlandToplevel.address}`
                            const w = windowByAddress[addr]

                            if (!w) continue
                            if (w.floating) continue
                            if (w.workspace?.id !== wsId) continue

                            arr.push(w)
                        }

                        arr.sort((a, b) => a.at[0] - b.at[0])
                        return arr
                    }

                    property int wsIndex: {
                        for (let i = 0; i < wsWindowsSorted.length; i++) {
                            if (wsWindowsSorted[i].address === windowData.address)
                                return i
                        }
                        return 0
                    }

                    property real workspaceTotalWindowWidth: {
                        let sum = 0
                        for (let i = 0; i < wsWindowsSorted.length; i++) {
                            const w = wsWindowsSorted[i]
                            sum += w.size?.[0] ?? 0
                        }
                        return sum * root.scaleRatio
                    }

                    onWorkspaceTotalWindowWidthChanged: { // we have to update widthMap here to prevent 'Binding Loop' error
                        if (workspaceTotalWindowWidth > 0 && root.hyprscrollingEnabled) {
                            root.widthMap.push(workspaceTotalWindowWidth)
                        }
                    }

                   function calculateXPosDev(extraOffset = 0) {
                        const arrayIndex = wsId - root.workspaceOffset - 1;
                        const focusedX = root.focusedXPerWorkspace[arrayIndex] ?? null;
                        const monitorX = root.monitor?.x || 0;
                        const reservedX = root.monitorData?.reserved?.[0] || 0;

                        if (focusedX === null) {
                            let x = xOffset + extraOffset;
                            for (let i = 0; i < wsIndex; i++) {
                                const winWidth = (wsWindowsSorted[i]?.size?.[0] || 0) * root.scaleRatio;
                                x += winWidth;
                            }
                            return x;
                        }

                        const focusedWindow = root.lastFocusedPerWorkspace[arrayIndex];
                        if (!focusedWindow) {
                            return xOffset + extraOffset;
                        }

                        const focusedWidth = (focusedWindow.size?.[0] || 0) * root.scaleRatio;
                        const workspaceCenterX = xOffset + root.workspaceImplicitWidth / 2;
                        const focusedStartX = workspaceCenterX - focusedWidth / 2;
                        const windowRealX = (windowData.at[0] - monitorX - reservedX) * root.scaleRatio;
                        const deltaX = windowRealX - focusedX;
                        return focusedStartX + deltaX + extraOffset - root.workspaceImplicitWidth / 2;
                    }


                    property int wsCount: wsWindowsSorted.length || 1

                    scrollWidth:  windowData.size[0] * root.scaleRatio 
                    scrollHeight: windowData.size[1] * root.scaleRatio

                    scrollX: windowData.floating ? xOffset + xWithinWorkspaceWidget : calculateXPosDev()
                    scrollY: windowData.floating ? yOffset + yWithinWorkspaceWidget : yOffset

                    property bool isActiveWindow: { // we have to set root.activeWindowData here instead of component.oncompleted
                        if (window.address == root.activeWindow?.address) {
                            root.activeWindowData = {
                                x: scrollX,
                                y: scrollY,
                                width: scrollWidth,
                                height: scrollHeight
                            }
                            return true
                        }
                        return false
                    }

                    // Offset on the canvas
                    property int workspaceColIndex: getWsColumn(windowData?.workspace.id)
                    property int workspaceRowIndex: getWsRow(windowData?.workspace.id)
                    xOffset: (root.workspaceImplicitWidth + workspaceSpacing) * workspaceColIndex
                    yOffset: (root.workspaceImplicitHeight + workspaceSpacing) * workspaceRowIndex
                    property real xWithinWorkspaceWidget: Math.max((windowData?.at[0] - (monitor?.x ?? 0) - monitorData?.reserved[0]) * root.scaleRatio, 0)
                    property real yWithinWorkspaceWidget: Math.max((windowData?.at[1] - (monitor?.y ?? 0) - monitorData?.reserved[1]) * root.scaleRatio, 0)                    

                    property int hoveringDir: 0 // 0: none, 1: right, 2: left
                    property bool hovering: false

                    Loader { // Hover indicator (only works with hyprscrolling)
                        active: root.hyprscrollingEnabled && !root.draggingWindowsFloating
                        anchors.verticalCenter: parent.verticalCenter
                        sourceComponent: Rectangle {
                            anchors.verticalCenter: parent.verticalCenter            

                            x: hoveringDir == 1 ? window.width / 2 : 0
                            implicitWidth: window.hovering ? window.width / 2 : 0
                            implicitHeight: window.height

                            color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.8)
                            opacity: window.hovering ? 1 : 0
                            radius: root.windowRounding

                            Behavior on x {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Behavior on opacity {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                        }
                    }
                    

                    DropArea { // Window drop
                        anchors.fill:  parent 
                        onEntered: {
                            parent.hovering = true
                            root.dragDropType = 1 // window
                            root.draggingTargetWindowAdress = windowData?.address
                            root.draggingTargetWorkspace = window?.wsId
                            const localX = drag.x
                            const half = width / 2

                            if (localX < half) {
                                root.draggingDirection = "l"
                                hoveringDir = 2
                            } else {
                                root.draggingDirection = "r"
                                hoveringDir = 1
                            }
                        }
                        onExited: {
                            parent.hovering = false
                            root.dragDropType = -1
                            if (root.draggingTargetWindowAdress == windowData?.address) root.draggingTargetWindowAdress = ""
                        }
                    }

                    Timer {
                        id: updateWindowPosition
                        interval: Config.options.hacks.arbitraryRaceConditionDelay 
                        repeat: false
                        running: false
                        onTriggered: {
                            if (windowData?.floating) return
                            window.x = calculateXPosDev()
                            window.y = yOffset
                        }
                    }

                    z: Drag.active ? root.windowDraggingZ : (root.windowZ + windowData?.floating)
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2
                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: hovered = true // For hover color change
                        onExited: hovered = false // For hover color change
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        drag.target: parent
                        onPressed: (mouse) => {
                            root.draggingFromWorkspace = windowData?.workspace.id
                            root.draggingFromWindowAddress = windowData?.address
                            root.draggingWindowsFloating = windowData?.floating
                            window.pressed = true
                            window.Drag.active = true
                            window.Drag.source = window
                            window.Drag.hotSpot.x = mouse.x
                            window.Drag.hotSpot.y = mouse.y
                            // console.log(`[OverviewWindow] Dragging window ${windowData?.address} from position (${window.x}, ${window.y})`)
                        }
                        onReleased: { // Dropping Event

                            if (root.dragDropType === 0) { // Workspace drop
                                const targetWorkspace = root.draggingTargetWorkspace
                                window.pressed = false
                                window.Drag.active = false
                                
                                root.draggingFromWorkspace = -1
                                if (targetWorkspace !== -1 && targetWorkspace !== windowData?.workspace.id) {
                                    Hyprland.dispatch(`movetoworkspacesilent ${targetWorkspace}, address:${window.windowData?.address}`)
                                    updateWindowPosition.restart()
                                }
                                else {
                                    if (!window.windowData.floating) {
                                        updateWindowPosition.restart()
                                        return
                                    }
                                    const percentageX = Math.round((window.x - xOffset) / root.workspaceImplicitWidth * 100)
                                    const percentageY = Math.round((window.y - yOffset) / root.workspaceImplicitHeight * 100)
                                    Hyprland.dispatch(`movewindowpixel exact ${percentageX}% ${percentageY}%, address:${window.windowData?.address}`)
                                }
                            } else if (root.dragDropType === 1) { // Window drop
                                const targetWindowAdress = root.draggingTargetWindowAdress
                                const targetWorkspace = root.draggingTargetWorkspace
                                
                                window.pressed = false
                                window.Drag.active = false
                                if (targetWindowAdress !== "" && targetWindowAdress !== windowData?.address) {
                                    if (root.draggingTargetWorkspace === root.draggingFromWorkspace) { // plugin directly supports same workspace switch
                                        Hyprland.dispatch(`layoutmsg swapaddrdir ${targetWindowAdress} ${root.draggingDirection} ${window.windowData?.address} true`)
                                    } else { // different workspace
                                        Hyprland.dispatch(`movetoworkspacesilent ${targetWorkspace}, address:${root.draggingFromWindowAddress}`)
                                        Qt.callLater(() => {
                                            Hyprland.dispatch(`layoutmsg swapaddrdir ${targetWindowAdress} ${root.draggingDirection} ${window.windowData?.address} true`)
                                        })
                                    }
                                }
                            } else {
                                window.pressed = false
                                window.Drag.active = false
                            }
                            Qt.callLater(() => {
                                root.draggingFromWindowAddress = "";
                                root.draggingTargetWindowAdress = "";
                                updateWindowPosition.restart();
                                HyprlandData.updateWindowList();
                            })   
                        }
                        onClicked: (event) => {
                            if (!windowData) return;

                            if (event.button === Qt.LeftButton) {
                                const sameWorkspaceWithTarget = windowData?.workspace.id === root.activeWindow?.workspace?.id

                                if (!root.hyprscrollingEnabled) {
                                    Hyprland.dispatch(`focuswindow address:${windowData.address}`)
                                    GlobalStates.overviewOpen = false; 
                                    return
                                }

                                if (sameWorkspaceWithTarget) {
                                    Hyprland.dispatch(`layoutmsg focusaddr ${windowData.address}`)
                                    GlobalStates.overviewOpen = false;
                                } else {
                                    Hyprland.dispatch(`focuswindow address:${windowData.address}`)
                                    Qt.callLater(() => {
                                        Hyprland.dispatch(`layoutmsg focusaddr ${windowData.address}`);
                                        GlobalStates.overviewOpen = false;
                                    });

                                }
                                event.accepted = true
                            } else if (event.button === Qt.MiddleButton) {
                                Hyprland.dispatch(`closewindow address:${windowData.address}`)
                                event.accepted = true
                            }
                        }

                        StyledToolTip {
                            extraVisibleCondition: false
                            alternativeVisibleCondition: dragArea.containsMouse && !window.Drag.active
                            text: `${windowData?.title}${windowData?.xwayland ? "[XWayland] " : ""}`
                        }
                    }
                }
            }

            Rectangle { // Focused workspace indicator
                id: focusedWorkspaceIndicator
                property int rowIndex: getWsRow(monitor.activeWorkspace?.id)
                property int colIndex: getWsColumn(monitor.activeWorkspace?.id)

                z: 999

                x: root.hyprscrollingEnabled ? root.activeWindowData?.x ?? 0 : (root.workspaceImplicitWidth + workspaceSpacing) * colIndex
                y: root.hyprscrollingEnabled ? root.activeWindowData?.y ?? 0 : (root.workspaceImplicitHeight + workspaceSpacing) * rowIndex
                width: root.hyprscrollingEnabled ? root.activeWindowData?.width ?? 0 : root.workspaceImplicitWidth + 4
                height: root.hyprscrollingEnabled ? root.activeWindowData?.height ?? 0 : root.workspaceImplicitHeight

                radius: root.windowRounding
                color: "transparent"
                border.width: 2
                border.color: root.activeWindow ? root.activeBorderColor : "transparent"
                Behavior on x {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on y {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on width {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on height {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }
}
