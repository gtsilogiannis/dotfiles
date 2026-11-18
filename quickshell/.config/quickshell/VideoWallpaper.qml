// Plays the video wallpaper only while its output shows an empty workspace:
// behind windows every frame makes Hyprland redraw and blur the whole screen.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR")
    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/scripts/set-wallpaper.sh"

    // Output that plays the video; empty while no video plays.
    property string output: ""
    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === root.output) ?? null
    readonly property var workspace: root.monitor?.activeWorkspace ?? null
    readonly property bool paused: !root.workspace || root.workspace.toplevels.values.length > 0
    onPausedChanged: root.sync()

    // The socket only exists while a video plays, so it is opened on demand.
    function sync() {
        if (root.output === "") return;
        if (socket.connected) {
            socket.send();
        } else {
            socket.connected = false;
            socket.connected = true;
        }
    }

    Socket {
        id: socket
        path: root.runtimeDir + "/mpvpaper.sock"
        onConnectedChanged: if (connected) send()

        function send() {
            write(JSON.stringify({ command: ["set_property", "pause", root.paused] }) + "\n");
            flush();
        }
    }

    // Rewritten in place (never removed) by the script, so the watcher survives.
    FileView {
        id: outputFile
        property bool read: false
        path: root.runtimeDir + "/mpvpaper.output"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            read = true;
            root.output = text().trim();
            root.sync();
        }
    }

    // The file appears at login (set-wallpaper.sh --resume); retry until then.
    Timer {
        interval: 2000
        repeat: true
        running: !outputFile.read
        onTriggered: outputFile.reload()
    }

    // A monitor plugged in or out: the script moves the video to the right
    // output. Hyprland sends several events per change, hence the delay.
    Timer {
        id: reoutput
        interval: 1500
        onTriggered: Quickshell.execDetached([root.script, "--reoutput"])
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name.startsWith("monitoradded") || event.name.startsWith("monitorremoved"))
                reoutput.restart();
        }
    }

    IpcHandler {
        target: "wallpaper"
        function sync(): void { root.sync(); }
    }
}
