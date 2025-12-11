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
    readonly property bool showPreviousToggle: Config.options.background.widgets.media.showPreviousToggle

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    property MprisPlayer currentPlayer
    property var artUrl: currentPlayer?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`

    property color artDominantColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer
    property QtObject blendedColors: AdaptedMaterialScheme {
        color: artDominantColor
    }

    property bool downloaded: false
    property string displayedArtFilePath: root.downloaded ? Qt.resolvedUrl(artFilePath) : ""

    implicitHeight: contentItem.implicitHeight
    implicitWidth: contentItem.implicitWidth

    property real controlsSize: 55 // a config option maybe?

    acceptedButtons: Qt.LeftButton | Qt.MiddleButton 
    onReleased: (mouse) => {
        if (mouse.button == Qt.MiddleButton) {
            root.nextPlayer()
        }
    }

    function nextPlayer() {
        root.currentPlayer = MprisController.players[(MprisController.players.indexOf(root.currentPlayer) + 1) % MprisController.players.length]
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0 // 2^0 = 1 color
        rescaleSize: 1 // Rescale to 1x1 pixel for faster processing
    }

    Component.onCompleted: {
        root.currentPlayer = MprisController.activePlayer
    }

    onArtFilePathChanged: {
        if (root.artUrl.length == 0) {
            root.artDominantColor = Appearance.m3colors.m3secondaryContainer
            return;
        }
        // Binding does not work in Process
        coverArtDownloader.targetFile = root.artUrl 
        coverArtDownloader.artFilePath = root.artFilePath
        // Download
        root.downloaded = false
        coverArtDownloader.running = true
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

    Item {
        id: contentItem

        implicitWidth: 200 // a config option maybe?
        implicitHeight: implicitWidth

        FadeLoader {
            id: blurEffectLoader
            anchors.fill: parent
            shown: Config.options.background.widgets.media.glowEffect
            sourceComponent: Image {
                id: blurredArt
                anchors.centerIn: parent
                source: root.displayedArtFilePath
                sourceSize.width: sourceSize.height
                sourceSize.height: contentItem.implicitWidth
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
        

        Rectangle { // Art background
            id: artBackground
            anchors.fill: parent
            radius: Appearance.rounding.full
            
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

        RippleButton { // play - pause bottom
            anchors {
                left: parent.left
                bottom: parent.bottom
            }
            implicitWidth: controlsSize
            implicitHeight: implicitWidth
            z: 2
            
            buttonRadius: currentPlayer.isPlaying ? Appearance.rounding.normal : controlsSize / 2
            colBackground: useAlbumColors ?  blendedColors.colSecondaryContainer : Appearance.colors.colSecondaryContainer
            colBackgroundHover: useAlbumColors ?  blendedColors.colSecondaryContainerHover : Appearance.colors.colSecondaryContainerHover
            colBackgroundToggled: useAlbumColors ?  blendedColors.colSecondaryContainerActive : Appearance.colors.colSecondaryContainerActive
            colRipple: useAlbumColors ? blendedColors.colSecondaryContainerActive : Appearance.colors.colSecondaryContainerActive
            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: 32
                text: currentPlayer.isPlaying ? "pause" : "play_arrow"
                fill: 1
                color: useAlbumColors ?  blendedColors.colTertiary : Appearance.colors.colTertiary
            }
            onClicked: {
                currentPlayer.togglePlaying()
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
                sourceComponent: RippleButton {
                    anchors.left: parent.left

                    implicitWidth: controlsSize
                    implicitHeight: implicitWidth
                    z: 2
                    buttonRadius: Appearance.rounding.full
                    colBackground: useAlbumColors ?  blendedColors.colTertiaryContainer : Appearance.colors.colTertiaryContainer
                    colBackgroundHover: useAlbumColors ?  blendedColors.colTertiaryContainerHover : Appearance.colors.colTertiaryContainerHover
                    colBackgroundToggled: useAlbumColors ?  blendedColors.colTertiaryContainerActive : Appearance.colors.colTertiaryContainerActive
                    colRipple: useAlbumColors ? blendedColors.colTertiaryContainerActive : Appearance.colors.colTertiaryContainerActive
                    MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: 32
                        text: "skip_previous"
                        fill: 1
                        color: useAlbumColors ?  blendedColors.colSecondary : Appearance.colors.colSecondary
                    }
                    onClicked: {
                        currentPlayer.previous()
                    }
                }
            }

            RippleButton {
                anchors.right: parent.right
                implicitWidth: controlsSize
                implicitHeight: implicitWidth
                z: 2
                buttonRadius: Appearance.rounding.full
                colBackground: useAlbumColors ?  blendedColors.colTertiaryContainer : Appearance.colors.colTertiaryContainer
                colBackgroundHover: useAlbumColors ?  blendedColors.colTertiaryContainerHover : Appearance.colors.colTertiaryContainerHover
                colBackgroundToggled: useAlbumColors ?  blendedColors.colTertiaryContainerActive : Appearance.colors.colTertiaryContainerActive
                colRipple: useAlbumColors ? blendedColors.colTertiaryContainerActive : Appearance.colors.colTertiaryContainerActive
                MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: 32
                    text: "skip_next"
                    fill: 1
                    color: useAlbumColors ?  blendedColors.colSecondary : Appearance.colors.colSecondary
                }
                onClicked: {
                    currentPlayer.next()
                }
            }

        }
    }
}