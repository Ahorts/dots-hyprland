import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs
import qs.services
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets



AbstractBackgroundWidget {
    id: root

    configEntryName: "media"

    readonly property bool useAlbumColors: Config.options.background.widgets.media.useAlbumColors
    readonly property bool useDynamicColors: root.useAlbumColors && root.currentPlayer != null 
    readonly property bool showPreviousToggle: Config.options.background.widgets.media.showPreviousToggle

    readonly property var playerList: MprisController.players
    
    property MprisPlayer currentPlayer : null
    property var artUrl: currentPlayer?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`

    property real widgetSize: 200
    property real controlsSize: 55 // a config option maybe?
    property real buttonIconSize: 30
    property bool showSwitchButton: false

    property color artDominantColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer
    property QtObject blendedColors: AdaptedMaterialScheme {
        color: artDominantColor
    }
    property var dynamicColors: {
        return {
            colPrimary: root.useDynamicColors                  ?  blendedColors.colPrimary                  : Appearance.colors.colPrimary,
            colPrimaryBackground: root.useDynamicColors        ?  blendedColors.colPrimaryContainer         : Appearance.colors.colPrimaryContainer,
            colPrimaryBackgroundHover: root.useDynamicColors   ?  blendedColors.colPrimaryContainerHover    : Appearance.colors.colPrimaryContainerHover,
            colPrimaryRipple: root.useDynamicColors            ?  blendedColors.colPrimaryContainerActive   : Appearance.colors.colPrimaryContainerActive,

            colSecondary: root.useDynamicColors                ?  blendedColors.colSecondary                : Appearance.colors.colSecondary,
            colSecondaryBackground: root.useDynamicColors      ?  blendedColors.colSecondaryContainer       : Appearance.colors.colSecondaryContainer,
            colSecondaryBackgroundHover: root.useDynamicColors ?  blendedColors.colSecondaryContainerHover  : Appearance.colors.colSecondaryContainerHover,
            colSecondaryRipple: root.useDynamicColors          ?  blendedColors.colSecondaryContainerActive : Appearance.colors.colSecondaryContainerActive,

            colTertiary: root.useDynamicColors                 ? blendedColors.colTertiary                  : Appearance.colors.colTertiary,
            colTertiaryBackground: root.useDynamicColors       ? blendedColors.colTertiaryContainer         : Appearance.colors.colTertiaryContainer,
            colTertiaryBackgroundHover: root.useDynamicColors  ? blendedColors.colTertiaryContainerHover    : Appearance.colors.colTertiaryContainerHover,
            colTertiaryRipple: root.useDynamicColors           ? blendedColors.colTertiaryContainerActive   : Appearance.colors.colTertiaryContainerActive
            
        }
    }


    property bool downloaded: false
    property string displayedArtFilePath: root.downloaded ? Qt.resolvedUrl(artFilePath) : ""
    // FIXME: find out to set player when its first openned

    implicitHeight: contentItem.implicitHeight
    implicitWidth: contentItem.implicitWidth

    // Switch button visiblity on hover
    hoverEnabled: true
    onEntered: {
        if (root.playerList.length <= 1) return
        showSwitchButton = true
    }
    onExited: showSwitchButton = false
        
    onPlayerListChanged: {
        if (root.displayedArtFilePath !== "") return 
        root.currentPlayer = root.playerList[0]
    }

    Component.onCompleted: initializePlayer()
    onArtFilePathChanged: updateArt()
    onCurrentPlayerChanged: updatePlayer()
    
    function nextPlayer() {
        root.currentPlayer = root.playerList[(root.playerList.indexOf(root.currentPlayer) + 1) % root.playerList.length]
    }

    function updateArt() {
        if (root.artUrl.length == 0) {
            root.artDominantColor = Appearance.m3colors.m3secondaryContainer
            return;
        }

        coverArtDownloader.targetFile = root.artUrl 
        coverArtDownloader.artFilePath = root.artFilePath
        root.downloaded = false
        coverArtDownloader.running = true
    }

    function initializePlayer() {
        if (root.playerList.length == 0) {
            root.currentPlayer = null
            root.displayedArtFilePath = ""
            return
        }
        if (MprisController.activePlayer == null) {
            root.currentPlayer = root.playerList[0]
            return
        }
        root.currentPlayer = MprisController.activePlayer
    }

    function updatePlayer() {
        if (root.currentPlayer != null) return
        root.initializePlayer()
    }

    
    Process { // Cover art downloader
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        command: [ "bash", "-c", `[ -f ${artFilePath} ] || curl -sSL '${targetFile}' -o '${artFilePath}'` ]
        onExited: (exitCode, exitStatus) => {
            root.downloaded = true
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0 // 2^0 = 1 color
        rescaleSize: 1 // Rescale to 1x1 pixel for faster processing
    }

    

    Item {
        id: contentItem

        implicitWidth: root.widgetSize // a config option maybe?
        implicitHeight: implicitWidth

        FadeLoader {
            id: blurEffectLoader
            anchors.fill: parent
            shown: Config.options.background.widgets.media.glowEffect
            property var source: root.displayedArtFilePath
            sourceComponent: Image {
                id: blurredArt
                anchors.centerIn: parent
                source: blurEffectLoader.source
                sourceSize.height: contentItem.implicitWidth
                sourceSize.width: sourceSize.height
                fillMode: Image.PreserveAspectCrop
                cache: false
                antialiasing: true
                asynchronous: true
                
                layer.enabled: true
                layer.effect: StyledBlurEffect {
                    source: blurredArt
                }

            }
        }

        FadeLoader {
            id: loopButtonLoader
            anchors {
                right: parent.right
                bottom: parent.bottom
            }
            z: 3
            shown: showSwitchButton
            sourceComponent: ControlButton {
                colBackground: root.dynamicColors.colPrimaryBackground
                colBackgroundHover: root.dynamicColors.colPrimaryBackgroundHover
                colRipple: root.dynamicColors.colPrimaryRipple
                symbolColor: root.dynamicColors.colSecondary
                symbolText: "360"
                onClicked: {
                    root.nextPlayer()
                }
            }
        }

        MaterialSymbol {
            id: contentItemIcon
            visible: root.displayedArtFilePath === ""
            anchors.centerIn: parent
            iconSize: 100
            fill: 1
            z: 1000
            color: root.currentPlayer.isPlaying ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
            text: "disc_full"
        }
        
        Rectangle { // Art background
            id: artBackground
            anchors.fill: parent
            radius: Appearance.rounding.full
            color: Appearance.colors.colPrimaryContainer
            
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: artBackground.width
                    height: artBackground.height
                    radius: artBackground.radius
                }
            }

            StyledImage { // Art image
                id: mediaArt
                property int size: parent.height
                anchors.fill: parent

                source: root.displayedArtFilePath
                fillMode: Image.PreserveAspectCrop
                cache: false
                antialiasing: true

                width: size
                height: size
                sourceSize.width: size
                sourceSize.height: size
            }
        }

        ControlButton {
            id: playButton
            anchors {
                left: parent.left
                bottom: parent.bottom
            }
            buttonRadius: root.currentPlayer.isPlaying ? Appearance.rounding.normal : controlsSize / 2
            colBackground: root.dynamicColors.colSecondaryBackground
            colBackgroundHover: root.dynamicColors.colSecondaryBackgroundHover
            colRipple: root.dynamicColors.colSecondaryRipple
            symbolText: root.currentPlayer.isPlaying ? "pause" : "play_arrow"
            symbolColor: useAlbumColors ?  blendedColors.colTertiary : Appearance.colors.colTertiary
            onClicked: {
                root.currentPlayer.togglePlaying()
            }
        }

        Rectangle {
            anchors {
                top: parent.top
                right: parent.right
            }
            implicitWidth: root.showPreviousToggle ? controlsSize * 2 : controlsSize
            implicitHeight: controlsSize
            z: 2
            radius: Appearance.rounding.full
            color: useAlbumColors ?  blendedColors.colTertiaryContainer : Appearance.colors.colTertiaryContainer

            Behavior on implicitWidth {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }

            FadeLoader {
                shown: root.showPreviousToggle
                sourceComponent: ControlButton {
                    anchors.left: parent.left
                    colBackground: root.dynamicColors.colTertiaryBackground
                    colBackgroundHover: root.dynamicColors.colTertiaryBackgroundHover
                    colRipple: root.dynamicColors.colTertiaryRipple
                    symbolColor: root.dynamicColors.colSecondary
                    symbolText: "skip_previous"
                    onClicked: {
                        currentPlayer.previous()
                    }
                }
            }

            ControlButton {
                anchors.right: parent.right 

                colBackground: root.dynamicColors.colTertiaryBackground
                colBackgroundHover: root.dynamicColors.colTertiaryBackgroundHover
                colRipple: root.dynamicColors.colTertiaryRipple
                symbolColor: root.dynamicColors.colSecondary
                symbolText: "skip_next"
                onClicked: {
                    currentPlayer.next()
                }
            }

        }
    }

    component ControlButton : RippleButton {
        id: button
        property string symbolText
        property color symbolColor
        
        z: 2
        implicitWidth: controlsSize
        implicitHeight: implicitWidth
        buttonRadius: Appearance.rounding.full

        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: root.buttonIconSize
            text: button.symbolText
            fill: 1
            color: button.symbolColor
        }
    }
}