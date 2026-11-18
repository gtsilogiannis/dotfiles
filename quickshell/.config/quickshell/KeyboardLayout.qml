// Keyboard layout as En / Gr; a click switches like ALT + SHIFT.
import QtQuick
import Quickshell.Io
import Quickshell.Hyprland

Pill {
    id: root

    property string layout: ""              // Hyprland's name, e.g. "English (US)", "Greek"
    readonly property string short: layout.startsWith("Greek") ? "Gr"
                                  : layout.startsWith("English") ? "En"
                                  : layout.slice(0, 2)

    visible: layout !== ""
    onClicked: switcher.running = true

    // Starting value: the active keymap of the main keyboard (the one typed on last).
    Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const keyboards = JSON.parse(this.text).keyboards;
                    const main = keyboards.find(k => k.main) ?? keyboards[0];
                    if (main) root.layout = main.active_keymap;
                } catch (e) {
                    console.warn("KeyboardLayout: cannot read hyprctl devices:", e);
                }
            }
        }
    }

    // "all": every keyboard switches together, so the pill stays true for each of them.
    Process {
        id: switcher
        command: ["hyprctl", "switchxkblayout", "all", "next"]
    }

    // Event data: KEYBOARD,LAYOUT, e.g. at-translated-set-2-keyboard,Greek
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout") return;
            const args = event.parse(2);
            if (args.length === 2 && args[1] !== "") root.layout = args[1];
        }
    }

    Label {
        text: root.short
        font.weight: Font.Medium
    }
}
