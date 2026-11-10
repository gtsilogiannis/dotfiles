// Pauses the video wallpaper while a window has focus and plays it on an
// empty workspace: behind glass windows every video frame makes Hyprland blur
// and redraw the whole screen. Talks to mpv through the IPC socket that
// scripts/set-wallpaper.sh gives mpvpaper; the script asks for a sync
// (qs ipc call wallpaper sync) each time it starts a video.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    property bool windowFocused: false
    onWindowFocusedChanged: root.sync()

    // The socket only exists while a video plays, so it is opened on demand.
    function sync() {
        if (socket.connected) {
            socket.send();
        } else {
            socket.connected = false;
            socket.connected = true;
        }
    }

    Socket {
        id: socket
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/mpvpaper.sock"
        onConnectedChanged: if (connected) send()

        function send() {
            write(JSON.stringify({ command: ["set_property", "pause", root.windowFocused] }) + "\n");
            flush();
        }
    }

    // Starting value; "{}" when no window has focus.
    Process {
        running: true
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.windowFocused = !!JSON.parse(this.text).address;
                } catch (e) {
                    root.windowFocused = false;
                }
                root.sync();
            }
        }
    }

    // Event data: the window address, empty when the focus moves to no window.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindowv2") root.windowFocused = event.data !== "";
        }
    }

    IpcHandler {
        target: "wallpaper"
        function sync(): void { root.sync(); }
    }
}
