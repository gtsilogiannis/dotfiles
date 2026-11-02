// CPU, memory, temperature and pending updates, polled once for all bars.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu: 0            // 0..1, busy share since the previous sample
    property real ram: 0            // 0..1, (MemTotal - MemAvailable) / MemTotal
    property real temp: 0           // °C, package temperature from coretemp
    property int updates: 0         // repo + AUR packages with a newer version

    property var previousCpu: null
    property string tempPath: ""

    function refreshUpdates() {
        updatesProc.running = true;
    }

    function parseCpu(text) {
        // First line: "cpu user nice system idle iowait irq softirq steal ..."
        const fields = text.split("\n")[0].trim().split(/\s+/).slice(1, 9).map(Number);
        const idle = fields[3] + fields[4];                   // idle + iowait
        const total = fields.reduce((a, b) => a + b, 0);
        if (root.previousCpu !== null && total > root.previousCpu.total)
            root.cpu = 1 - (idle - root.previousCpu.idle) / (total - root.previousCpu.total);
        root.previousCpu = { total: total, idle: idle };
    }

    function parseMem(text) {
        const kib = key => Number((text.match(new RegExp("^" + key + ":\\s+(\\d+)", "m")) ?? [0, 0])[1]);
        const total = kib("MemTotal");
        if (total > 0) root.ram = 1 - kib("MemAvailable") / total;
    }

    FileView { id: statFile; path: "/proc/stat"; onLoaded: root.parseCpu(text()) }
    FileView { id: memFile; path: "/proc/meminfo"; onLoaded: root.parseMem(text()) }
    FileView { id: tempFile; path: root.tempPath; onLoaded: root.temp = parseInt(text()) / 1000 }

    // The hwmonN number changes between boots (ARCH P34), so resolve it once through the device path.
    Process {
        running: true
        command: ["sh", "-c", "echo /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input"]
        stdout: StdioCollector { onStreamFinished: root.tempPath = text.trim() }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
            if (root.tempPath !== "") tempFile.reload();
        }
    }

    Process {
        id: updatesProc
        command: ["sh", "-c", "(checkupdates; yay -Qum) 2>/dev/null | wc -l"]
        stdout: StdioCollector { onStreamFinished: root.updates = parseInt(text) || 0 }
    }

    Timer {
        interval: 600000                // 10 minutes, same as the Waybar module
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshUpdates()
    }
}
