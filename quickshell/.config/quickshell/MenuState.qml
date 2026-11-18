// The open full-screen menu; opening one closes the others.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string open: ""            // "" when no menu is open
    property real closedAt: 0
    property string closedName: ""

    function close() {
        if (root.open === "") return;
        root.closedName = root.open;
        root.open = "";
        root.closedAt = Date.now();
    }

    // A keybind or bar click that arrives right after a click outside closed
    // the same menu must not reopen it.
    function toggle(name) {
        if (root.open === name) root.close();
        else if (!(root.closedName === name && Date.now() - root.closedAt < 300)) root.open = name;
    }

    // qs ipc call menu toggle launcher   (keybinds in hypr/modules/binds.lua)
    IpcHandler {
        target: "menu"
        function toggle(name: string): void { root.toggle(name); }
        function close(): void { root.close(); }
    }
}
