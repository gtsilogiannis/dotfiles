// Desktop mode and the opaque-windows switch. scripts/mode.sh owns both files,
// so Hyprland and the shell can never disagree about the mode.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/desktop"
    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/scripts/mode.sh"

    property string mode: "browsing"
    readonly property bool focus: root.mode === "focus"
    property bool opaque: false             // browsing only: windows at full opacity

    // Emitted on changes after the first read, so the OSD stays quiet at login.
    signal modeSwitched()
    signal opaqueSwitched()

    function toggleMode() {
        Quickshell.execDetached([root.script, "toggle"]);
    }

    function toggleOpaque() {
        Quickshell.execDetached([root.script, "opaque", "toggle"]);
    }

    FileView {
        id: modeFile
        property bool read: false
        path: root.stateDir + "/mode"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const value = text().trim() === "focus" ? "focus" : "browsing";
            if (value === root.mode) { read = true; return; }
            root.mode = value;
            if (read) root.modeSwitched();
            read = true;
        }
    }

    FileView {
        id: opaqueFile
        property bool read: false
        path: root.stateDir + "/opaque"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const value = text().trim() === "on";
            if (value === root.opaque) { read = true; return; }
            root.opaque = value;
            if (read) root.opaqueSwitched();
            read = true;
        }
    }

    // mode.sh init may create the files after the shell starts: retry until both
    // have been read once, then the watchers take over.
    Timer {
        interval: 2000
        repeat: true
        running: !modeFile.read || !opaqueFile.read
        onTriggered: {
            if (!modeFile.read) modeFile.reload();
            if (!opaqueFile.read) opaqueFile.reload();
        }
    }
}
