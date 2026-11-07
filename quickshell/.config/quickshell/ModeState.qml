// Desktop mode (browsing / focus) and the opaque-windows switch, both owned by
// scripts/mode.sh, which writes them to ~/.local/state/desktop/. The shell only
// reads the files and asks the script to change them, so Hyprland and Quickshell
// can never disagree about the mode.
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

    // The files may not exist yet when the shell starts (first login after an
    // update; mode.sh init creates them two seconds after the shell). Retry
    // until both have been read once; after that the watchers take over.
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
