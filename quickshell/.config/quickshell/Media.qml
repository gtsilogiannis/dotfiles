// Now playing: play/pause button and "title · artist", or only a muted icon
// when no player is open. Browsers are ignored,
// as in the Waybar module. Left click toggles, right click skips, scroll seeks tracks.
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

Pill {
    id: root

    readonly property var players: Mpris.players.values.filter(p => !/firefox|zen|chrom/i.test(p.identity + p.dbusName))
    // Prefer the player that is playing, else the first one (e.g. Spotify paused).
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property string track: player
        ? [player.trackTitle, player.trackArtist].filter(s => s !== "").join("  ·  ")
        : ""

    interactive: player !== null
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) { if (player.canGoNext) player.next(); }
        else if (player.canTogglePlaying) player.togglePlaying();
    }
    onScrolled: delta => {
        if (delta > 0 && player?.canGoPrevious) player.previous();
        else if (delta < 0 && player?.canGoNext) player.next();
    }

    MaterialIcon {
        icon: root.player === null ? "music_off" : root.player.isPlaying ? "pause" : "play_arrow"
        filled: true
        color: root.player === null ? Theme.surfaceTextMuted : Theme.primary
    }
    Label {
        visible: root.player !== null           // no player (Spotify closed): icon only
        text: root.track || (root.player?.identity ?? "")
        elide: Text.ElideRight
        Layout.maximumWidth: 320
    }
}
