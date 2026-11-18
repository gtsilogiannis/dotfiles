// Keeps the session awake: while on, every bar holds an idle inhibitor, so
// hypridle never dims, locks or blanks. Off at every login.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property bool active: false

    function toggle() {
        active = !active;
    }
}
