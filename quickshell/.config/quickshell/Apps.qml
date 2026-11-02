// Maps a window's app id (firefox, kitty, dev.zed.Zed) to its desktop entry,
// for a readable name and the icon from the icon theme.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    function entry(appId) {
        return appId ? DesktopEntries.heuristicLookup(appId) : null;
    }

    function name(appId) {
        const e = entry(appId);
        return e?.name || appId || "";
    }

    // Theme icon of the app: the entry's Icon=, then the app id as given and in lowercase.
    // Returns "" when none exists, so callers can draw a glyph instead of the missing texture.
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
