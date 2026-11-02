// Open/closed state of the control center, shared by the bar button,
// the keybind (SUPER + N) and the window itself.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false
    property real closedAt: 0

    function close() {
        if (!root.open) return;
        root.open = false;
        root.closedAt = Date.now();
    }

    // A click on the bar button first closes the panel (click outside), then
    // arrives as a toggle: ignoring it right after a close keeps it closed.
    function toggle() {
        if (root.open) root.close();
        else if (Date.now() - root.closedAt > 300) root.open = true;
    }

    // qs ipc call controlcenter toggle   (bound to SUPER + N in hyprland.lua)
    IpcHandler {
        target: "controlcenter"
        function toggle(): void { root.toggle(); }
        function close(): void { root.close(); }
    }
}
