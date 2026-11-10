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
    property string page: "main"            // main | wifi | bluetooth
    // Opened from the bar on one view (the network pill): that view stands alone,
    // with no way back to the main panel. Only the bell and SUPER + N open the panel.
    property bool standalone: false

    function close() {
        if (!root.open) return;
        root.open = false;
        root.standalone = false;
        root.closedAt = Date.now();
    }

    // A click on the bar button first closes the panel (click outside), then
    // arrives as a toggle: ignoring it right after a close keeps it closed.
    function toggle() {
        if (root.open) root.close();
        else if (Date.now() - root.closedAt > 300) { root.standalone = false; root.open = true; }
    }

    // Opens straight on one view, e.g. the Wi-Fi list from the bar, as a standalone view.
    function openPage(name) {
        root.page = name;
        root.standalone = true;
        root.open = true;
    }

    // Bar pill for one view: same close-then-click rule as toggle().
    function togglePage(name) {
        if (root.open) root.close();
        else if (Date.now() - root.closedAt > 300) root.openPage(name);
    }

    // Back arrow, Esc or "turn off" inside a view: to the main panel, or closed if standalone.
    function back() {
        if (root.standalone) root.close();
        else root.page = "main";
    }

    // qs ipc call controlcenter toggle   (bound to SUPER + N in hyprland.lua)
    IpcHandler {
        target: "controlcenter"
        function toggle(): void { root.toggle(); }
        function close(): void { root.close(); }
        function openPage(name: string): void { root.openPage(name); }
    }
}
