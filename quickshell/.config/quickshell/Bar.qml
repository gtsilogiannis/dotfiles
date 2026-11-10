// Top bar: workspaces on the left, media and clock in the center,
// system modules on the right. The bar itself is transparent: every module
// is its own glass island, with empty space between them.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar

    anchors { top: true; left: true; right: true }
    // Same distance from the screen edges as the windows (gaps_out).
    margins { top: Theme.gap; left: Theme.gap; right: Theme.gap }
    implicitHeight: Theme.barHeight
    color: "transparent"

    // Hyprland matches this name in hl.layer_rule to blur behind the islands.
    WlrLayershell.namespace: "quickshell-bar"

    // Caffeine: the bars are always mapped, so their inhibitors hold off hypridle.
    IdleInhibitor {
        window: bar
        enabled: Caffeine.active
    }

    Workspaces {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: Theme.gap

        Media {}
        Clock {}
    }

    StatusModules {
        window: bar
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
    }
}
