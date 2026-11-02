// Right side of the bar, left to right: tray, updates, temperature, CPU, RAM,
// volume, notifications, network, power.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RowLayout {
    id: root

    required property var window

    // Temperature, CPU and RAM open btop in a normal tiled kitty. The smaller font gives
    // btop its minimum of 80x24 cells even in a half-height tile.
    function openMonitor() {
        Quickshell.execDetached(["kitty", "-o", "font_size=9.5", "--title", "btop", "-e", "btop"]);
    }

    spacing: Theme.spacing

    Tray { window: root.window }

    Stat {
        icon: "inventory_2"
        value: String(SystemStats.updates)
        accent: SystemStats.updates > 0 ? Theme.tertiary : Theme.primary
        // Left: upgrade in kitty (what the up alias does), then recount. Right: recount only.
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) SystemStats.refreshUpdates();
            else if (!upgrade.running) upgrade.running = true;
        }

        // bash -c is not an interactive zsh, so .zshrc (and fastfetch) is not loaded.
        Process {
            id: upgrade
            command: ["kitty", "--title", "System update", "-e", "bash", "-c",
                "yay; read -n 1 -s -r -p 'Done. Press any key to close.'"]
            onExited: SystemStats.refreshUpdates()
        }
    }

    Stat {
        icon: "thermostat"
        value: `${Math.round(SystemStats.temp)}°`
        accent: SystemStats.temp >= 80 ? Theme.error : Theme.primary     // same threshold as Waybar
        onClicked: root.openMonitor()
    }

    Stat {
        icon: "memory"
        value: `${Math.round(SystemStats.cpu * 100)}%`
        onClicked: root.openMonitor()
    }

    Stat {
        icon: "memory_alt"
        value: `${Math.round(SystemStats.ram * 100)}%`
        onClicked: root.openMonitor()
    }

    Volume {}

    Notifications {}

    Network {}

    Stat {
        icon: "power_settings_new"
        accent: Theme.error
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/rofi/powermenu.sh"])
    }
}
