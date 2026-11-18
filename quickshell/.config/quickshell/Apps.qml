// Maps a window's app id (firefox, kitty, dev.zed.Zed) to its desktop entry,
// for a readable name and the icon from the icon theme.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // DesktopEntries scans in the background on first use and returns null until
    // then; reading the model here re-runs every binding once the scan is done.
    function entry(appId) {
        const loaded = DesktopEntries.applications.values.length;
        return appId && loaded > 0 ? DesktopEntries.heuristicLookup(appId) : null;
    }

    function name(appId) {
        const e = entry(appId);
        return e?.name || appId || "";
    }

    // Icon=, then the app id as is and in lowercase; "" lets callers draw a glyph
    function icon(appId) {
        const e = entry(appId);
        for (const name of [e?.icon, appId, appId?.toLowerCase()]) {
            if (!name) continue;
            const path = Quickshell.iconPath(name, true);
            if (path !== "") return path;
        }
        return "";
    }

    // App id of a Hyprland window: the Wayland handle once known, else the class from IPC.
    function idOf(hyprToplevel) {
        return hyprToplevel?.wayland?.appId || hyprToplevel?.lastIpcObject?.class || "";
    }
}
