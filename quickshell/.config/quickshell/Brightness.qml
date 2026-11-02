// Screen brightness through brightnessctl (the same tool as the brightness keys).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real value: 0              // 0..1
    property bool available: false
    property int pending: 0

    function refresh() {
        reader.running = true;
    }

    function set(v) {
        root.value = Math.max(0.01, Math.min(1, v));    // never fully black
        root.pending = Math.round(root.value * 100);
        writer.restart();                               // one brightnessctl call per drag pause
    }

    // brightnessctl -m: "device,class,current,percent%,max"
    Process {
        id: reader
        running: true
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                if (fields.length >= 5) {
                    root.available = true;
                    root.value = parseInt(fields[3]) / 100;
                }
            }
        }
    }

    Timer {
        id: writer
        interval: 60
        onTriggered: Quickshell.execDetached(["brightnessctl", "-q", "set", `${root.pending}%`])
    }
}
