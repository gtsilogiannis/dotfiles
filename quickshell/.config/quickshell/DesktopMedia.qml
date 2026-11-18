// Media card on the depth desktop; hidden without a player (browsers ignored).
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.Mpris

Item {
    id: root

    required property Item backdrop             // the wallpaper Image of the desktop layer

    readonly property var players: Mpris.players.values.filter(p => !/firefox|zen|chrom/i.test(p.identity + p.dbusName))
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool shown: player !== null

    readonly property int pad: 14
    readonly property int artSize: 84

    implicitWidth: 380
    implicitHeight: artSize + 2 * pad
    opacity: shown ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    DesktopGlass { backdrop: root.backdrop }

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: 14

        Rectangle {
            Layout.preferredWidth: root.artSize
            Layout.preferredHeight: root.artSize
            radius: Theme.radius
            color: Qt.alpha(Theme.surfaceContainerHigh, 0.6)

            MaterialIcon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                icon: "music_note"
                font.pixelSize: 32
                color: Theme.surfaceTextMuted
            }

            // Rounded art: the image goes through a mask of the same rectangle.
            Image {
                id: art
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                sourceSize.width: root.artSize * 2      // sharp on a 2x scale, still small
                sourceSize.height: root.artSize * 2
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: artShape
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }
            }
            Item {
                id: artShape
                anchors.fill: parent
                visible: false
                layer.enabled: true
                Rectangle { anchors.fill: parent; radius: Theme.radius }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Label {
                text: root.player?.trackTitle || root.player?.identity || ""
                font.pixelSize: 16
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Label {
                text: root.player?.trackArtist ?? ""
                font.pixelSize: 13
                color: Theme.surfaceTextMuted
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 18
                Layout.topMargin: 6

                Repeater {
                    model: [
                        { icon: "skip_previous", run: () => root.player.previous(), can: () => root.player?.canGoPrevious },
                        { icon: root.player?.isPlaying ? "pause" : "play_arrow", run: () => root.player.togglePlaying(), can: () => root.player?.canTogglePlaying },
                        { icon: "skip_next", run: () => root.player.next(), can: () => root.player?.canGoNext }
                    ]

                    MaterialIcon {
                        required property var modelData
                        icon: modelData.icon
                        filled: true
                        font.pixelSize: 26
                        color: Theme.primary
                        opacity: modelData.can() ? 1 : 0.4
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (parent.modelData.can()) parent.modelData.run()
                        }
                    }
                }
            }
        }
    }
}
