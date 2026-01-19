//TODO: remove unnesessary imports

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions
import qs.modules.common.utils
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Hyprland

Item {
    id: root

    readonly property MprisPlayer activePlayer: MprisController.activePlayer

    Layout.fillHeight: true
    implicitHeight: Appearance.sizes.barHeight
    implicitWidth: Config.options.bar.mediaLyrics.width

    Behavior on implicitWidth {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    LrclibLyrics {
        id: lrclibLyrics
        enabled: (root.activePlayer?.trackTitle?.length > 0) && (root.activePlayer?.trackArtist?.length > 0) && root.visible
        title: root.activePlayer?.trackTitle ?? ""
        artist: root.activePlayer?.trackArtist ?? ""
        duration: root.activePlayer?.length ?? 0
        position: root.activePlayer?.position ?? 0
        selectedId: LyricsService.selectedId
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: (event) => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                activePlayer.next();
            } else if (event.button === Qt.LeftButton) {
                GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
            }
        }
    }

    Item {
        id: lyricScroller
        anchors.fill: parent
        clip: true

        readonly property bool hasSyncedLines: lrclibLyrics.lines.length > 0
        readonly property int rowHeight: Math.max(10, Math.min(Math.floor(height / 3), Appearance.font.pixelSize.smallie))
        readonly property real baseY: Math.max(0, Math.round((height - rowHeight * 3) / 2))
        readonly property real downScale: Appearance.font.pixelSize.smaller / Appearance.font.pixelSize.smallie
        
        readonly property int targetCurrentIndex: hasSyncedLines ? lrclibLyrics.currentIndex : -1
        
        readonly property string targetPrev: hasSyncedLines ? lrclibLyrics.prevLineText : ""
        readonly property string targetCurrent: hasSyncedLines ? (lrclibLyrics.currentLineText || "♪") : lrclibLyrics.displayText
        readonly property string targetNext: hasSyncedLines ? lrclibLyrics.nextLineText : ""

        property int lastIndex: -1
        property bool isMovingForward: true
        
        onTargetCurrentIndexChanged: {
            if (targetCurrentIndex !== lastIndex) {
                isMovingForward = targetCurrentIndex > lastIndex;
                lastIndex = targetCurrentIndex;
                scrollAnimation.restart();
            }
        }

        property real scrollOffset: 0
        
        SequentialAnimation {
            id: scrollAnimation
            PropertyAction { // instant
                target: lyricScroller
                property: "scrollOffset"
                value: lyricScroller.isMovingForward ? -lyricScroller.rowHeight : lyricScroller.rowHeight 
            }
            NumberAnimation { // smooth
                target: lyricScroller
                property: "scrollOffset"
                to: 0
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        readonly property real animProgress: Math.abs(scrollOffset) / rowHeight
        readonly property real dimOpacity: 0.6
        readonly property real activeOpacity: 1.0

        Column {
            width: parent.width
            spacing: 0
            y: lyricScroller.baseY - lyricScroller.scrollOffset

            LyricLine {
                text: lyricScroller.targetPrev
                highlight: false
                
                opacity: (lyricScroller.isMovingForward) 
                    ? lyricScroller.dimOpacity + (lyricScroller.activeOpacity - lyricScroller.dimOpacity) * lyricScroller.animProgress
                    : lyricScroller.dimOpacity
                    
                scale: (lyricScroller.isMovingForward)
                    ? lyricScroller.downScale + (1.0 - lyricScroller.downScale) * lyricScroller.animProgress
                    : lyricScroller.downScale
            }

            LyricLine {
                text: lyricScroller.targetCurrent
                highlight: true
                
                opacity: lyricScroller.activeOpacity - (lyricScroller.activeOpacity - lyricScroller.dimOpacity) * lyricScroller.animProgress
                scale: 1.0 - (1.0 - lyricScroller.downScale) * lyricScroller.animProgress
            }

            LyricLine {
                text: lyricScroller.targetNext
                highlight: false
                
                opacity: (!lyricScroller.isMovingForward)
                    ? lyricScroller.dimOpacity + (lyricScroller.activeOpacity - lyricScroller.dimOpacity) * lyricScroller.animProgress
                    : lyricScroller.dimOpacity

                scale: (!lyricScroller.isMovingForward)
                    ? lyricScroller.downScale + (1.0 - lyricScroller.downScale) * lyricScroller.animProgress
                    : lyricScroller.downScale
            }
        }
    }

    component LyricLine: StyledText {
        property bool highlight: false

        color: highlight ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext

        width: parent.width
        height: lyricScroller.rowHeight
        font.pixelSize: Appearance.font.pixelSize.smallie
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

}