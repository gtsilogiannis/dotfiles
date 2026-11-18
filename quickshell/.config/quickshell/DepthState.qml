// Depth wallpaper state: a wallpaper from ~/Pictures/wallpapers/depth/ with a
// cutout (scripts/make-depth.sh), in browsing mode. Read by the desktop layer and the bars.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property string depthDir: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/depth"

    property string wallpaper: ""
    readonly property bool isDepth: root.wallpaper.indexOf("/wallpapers/depth/") >= 0
    readonly property string stem: root.wallpaper.split("/").pop().replace(/\.[^.]*$/, "")
    property var meta: null                     // parsed .depth.json, null without a cutout
    readonly property bool active: root.isDepth && root.meta !== null && !ModeState.focus

    onWallpaperChanged: root.meta = null

    // Active and the workspace on this screen has no windows
    function shownOn(screen) {
        if (!root.active || !screen) return false;
        // From the model, not monitorFor(), so new monitors re-evaluate it
        const ws = Hyprland.monitors.values.find(m => m.name === screen.name)?.activeWorkspace ?? null;
        return ws !== null && ws.toplevels.values.length === 0;
    }

    // Written in place by set-wallpaper.sh on every change.
    FileView {
        id: pathFile
        property bool read: false
        path: Quickshell.env("HOME") + "/.cache/current_wallpaper.path"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            read = true;
            root.wallpaper = text().trim();
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: !pathFile.read
        onTriggered: pathFile.reload()
    }

    FileView {
        path: root.isDepth ? root.depthDir + "/" + root.stem + ".depth.json" : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const m = JSON.parse(text());
                root.meta = m.width > 0 && m.height > 0 && m.cutout ? m : null;
            } catch (e) {
                root.meta = null;
            }
        }
        onLoadFailed: root.meta = null
    }
}
