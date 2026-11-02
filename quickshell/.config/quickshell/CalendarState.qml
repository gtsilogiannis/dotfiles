// Open/closed state of the calendar popup under the clock.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool open: false
    property real closedAt: 0

    function close() {
        if (!root.open) return;
        root.open = false;
        root.closedAt = Date.now();
    }

    // Same rule as the control center: a click on the clock that just closed
    // the popup (click outside) must not reopen it.
    function toggle() {
        if (root.open) root.close();
        else if (Date.now() - root.closedAt > 300) root.open = true;
    }
}
