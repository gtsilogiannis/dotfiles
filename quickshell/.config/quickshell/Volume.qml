// Default output volume. Left click: mixer popup, right click: mute, scroll: ±5% (max 100%).
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Stat {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    icon: muted || volume === 0 ? "volume_off"
        : volume < 0.34 ? "volume_mute"
        : volume < 0.67 ? "volume_down"
        : "volume_up"
    value: muted ? "muted" : `${Math.round(volume * 100)}%`
    accent: muted ? Theme.surfaceTextMuted : Theme.primary

    // volume and muted are only valid while the node is bound by a tracker.
    PwObjectTracker { objects: [root.sink] }

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            if (sink?.audio) sink.audio.muted = !sink.audio.muted;
        } else {
            Quickshell.execDetached([Quickshell.shellDir + "/scripts/volume-menu.sh"]);
        }
    }
    onScrolled: delta => {
        if (!sink?.audio) return;
        const step = delta > 0 ? 0.05 : -0.05;
        sink.audio.volume = Math.min(1, Math.max(0, volume + step));     // capped at 100%, like wpctl -l 1
    }
}
