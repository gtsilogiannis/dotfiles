// Platform profile (lenovo-wmi-gamezone): a click cycles quiet, balanced and
// performance; max-power and custom step back to balanced. Writable via the udev rule.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string path: "/sys/class/platform-profile/platform-profile-0/profile"
    property string profile: ""
    property bool writable: false

    readonly property var cycle: ["low-power", "balanced", "performance"]
    readonly property var names: ({
        "low-power": "Quiet",
        "balanced": "Balanced",
        "performance": "Performance",
        "max-power": "Max power",
        "custom": "Custom"
    })
    readonly property var icons: ({
        "low-power": "eco",
        "balanced": "balance",
        "performance": "speed",
        "max-power": "local_fire_department",
        "custom": "tune"
    })
    readonly property string label: names[profile] ?? "Power"
    readonly property string icon: icons[profile] ?? "speed"

    // Fn + Q raises no inotify event, so the control center polls while open
    function refresh() {
        file.reload();
    }

    function checkAccess() {
        probe.running = true;
    }

    function next() {
        if (!writable || writer.running || profile === "") return;
        const i = cycle.indexOf(profile);
        const target = i < 0 ? "balanced" : cycle[(i + 1) % cycle.length];
        writer.command = ["sh", "-c", 'printf %s "$1" > "$2"', "sh", target, path];
        writer.running = true;
    }

    FileView {
        id: file
        path: root.path
        onLoaded: root.profile = text().trim()
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

    Component.onCompleted: {
        refresh();
        checkAccess();
    }
}
