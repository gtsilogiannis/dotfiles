// Blue-light filter: hyprsunset runs while the filter is on and resets the
// colors when it is stopped.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool active: sunset.running
    property int temperature: 4500          // Kelvin; lower is warmer

    function toggle() {
        sunset.running = !sunset.running;
    }

    Process {
        id: sunset
        command: ["hyprsunset", "-t", String(root.temperature)]
    }
}
