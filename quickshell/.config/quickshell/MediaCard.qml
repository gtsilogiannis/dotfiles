// Player card: album art, title, artist, previous / play-pause / next.
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

Card {
    id: root

    readonly property var players: Mpris.players.values.filter(p => !/firefox|zen|chrom/i.test(p.identity + p.dbusName))
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null

    visible: player !== null

    RowLayout {
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            radius: 10
            color: Qt.alpha(Theme.surfaceContainerHigh, 0.9)
            clip: true

            MaterialIcon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                icon: "music_note"
                color: Theme.surfaceTextMuted
            }
            Image {
                id: art
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Label {
                text: root.player?.trackTitle || root.player?.identity || ""
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Label {
                text: root.player?.trackArtist ?? ""
                color: Theme.surfaceTextMuted
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 14
                Layout.topMargin: 4

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
                        font.pixelSize: 24
                        color: Theme.primary
                        opacity: modelData.can() ? 1 : 0.4
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (parent.modelData.can()) parent.modelData.run()
                        }
                    }
                }
            }
        }
    }
}
