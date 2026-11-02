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

    function icon(appId) {
        const e = entry(appId);
        // Falls back to the generic icon when neither the entry nor the app id names a theme icon.
        return Quickshell.iconPath(e?.icon || appId || "", "application-x-executable");
    }

    // App id of a Hyprland window: the Wayland handle once known, else the class from IPC.
    function idOf(hyprToplevel) {
        return hyprToplevel?.wayland?.appId || hyprToplevel?.lastIpcObject?.class || "";
    }
}
