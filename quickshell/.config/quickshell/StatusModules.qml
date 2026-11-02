// Right side of the bar, left to right: tray, updates, temperature, CPU, RAM,
// volume, notifications, network, power.
import QtQuick
import QtQuick.Layouts
import Quickshell

RowLayout {
    id: root

    required property var window

    spacing: Theme.spacing

    Tray { window: root.window }

    Stat {
        icon: "inventory_2"
        value: String(SystemStats.updates)
        accent: SystemStats.updates > 0 ? Theme.tertiary : Theme.primary
        // Left: upgrade in kitty, then recount. Right: recount only.
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                SystemStats.refreshUpdates();
            } else {
                Quickshell.execDetached(["kitty", "--title", "System update", "-e", "bash", "-c",
                    "yay; read -n 1 -s -r -p 'Done. Press any key to close.'"]);
            }
        }
    }

    Stat {
        icon: "thermostat"
        value: `${Math.round(SystemStats.temp)}°`
        accent: SystemStats.temp >= 80 ? Theme.error : Theme.primary     // same threshold as Waybar
        interactive: false
    }

    Stat {
        icon: "memory"
        value: `${Math.round(SystemStats.cpu * 100)}%`
        interactive: false
    }

    Stat {
        icon: "memory_alt"
        value: `${Math.round(SystemStats.ram * 100)}%`
        interactive: false
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
