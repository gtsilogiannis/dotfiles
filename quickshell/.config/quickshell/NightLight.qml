// Blue-light filter: hyprsunset runs while on and resets the colors on exit.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool active: sunset.running
    property int temperature: 3400          // Kelvin; lower is warmer

    function toggle() {
        sunset.running = !sunset.running;
    }

    Process {
        id: sunset
        command: ["hyprsunset", "-t", String(root.temperature)]
    }
}
