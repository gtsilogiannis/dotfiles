// Right side of the bar: tray, updates (browsing only), stats, volume, layout,
// control center, battery, power.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RowLayout {
    id: root

    required property var window

    // The stats pill opens btop in a normal tiled kitty. The smaller font gives
    // btop its minimum of 80x24 cells even in a half-height tile.
    function openMonitor() {
        Quickshell.execDetached(["kitty", "-o", "font_size=9.5", "--title", "btop", "-e", "btop"]);
    }

    spacing: Theme.gap                  // empty space between the islands

    Tray { window: root.window }

    Stat {
        visible: !ModeState.focus
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

    // Temperature · CPU · RAM in one pill, e.g. 52° · 6% · 31%, in every mode.
    Stat {
        icon: "monitoring"
        value: `${Math.round(SystemStats.temp)}° · ${Math.round(SystemStats.cpu * 100)}% · ${Math.round(SystemStats.ram * 100)}%`
        accent: SystemStats.temp >= 80 ? Theme.error : Theme.primary
        onClicked: root.openMonitor()
    }

    Volume {}

    KeyboardLayout {}

    ControlCenterButton {}

    // The battery draws its own shape, so it sits on a plain glass island.
    Glass {
        implicitWidth: battery.implicitWidth + 22
        Battery { id: battery; anchors.centerIn: parent }
    }

    Stat {
        icon: "power_settings_new"
        accent: Theme.error
        onClicked: MenuState.toggle("power")
    }
}
