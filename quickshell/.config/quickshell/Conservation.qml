// Battery conservation mode: ideapad_acpi holds the charge near 80%.
// The udev rule in system/etc/udev/rules.d/90-lenovo-power.rules makes the
// attribute writable for the wheel group; without it the tile stays disabled.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string path: "/sys/bus/platform/devices/VPC2004:00/conservation_mode"
    property bool active: false
    property bool writable: false

    // Re-read the value; also re-check write access (the rule may have been installed since).
    function refresh() {
        file.reload();
        probe.running = true;
    }

    function toggle() {
        if (!writable || writer.running) return;
        writer.command = ["sh", "-c", 'printf %s "$1" > "$2"', "sh", active ? "0" : "1", path];
        writer.running = true;
    }

    FileView {
        id: file
        path: root.path
        onLoaded: root.active = text().trim() === "1"
    }

    Process {
        id: probe
        command: ["test", "-w", root.path]
        onExited: (exitCode, exitStatus) => root.writable = exitCode === 0
    }

    // sysfs attributes are written in place: a plain redirect, not an atomic rename.
    Process {
        id: writer
        onExited: (exitCode, exitStatus) => file.reload()
    }

    Component.onCompleted: refresh()
}
