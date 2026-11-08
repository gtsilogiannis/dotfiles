// Keeps the session awake: every bar holds a Wayland idle inhibitor while this
// is on, and hypridle skips its dim / lock / screen-off steps.
// Starts off with every session.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property bool active: false

    function toggle() {
        active = !active;
    }
}
