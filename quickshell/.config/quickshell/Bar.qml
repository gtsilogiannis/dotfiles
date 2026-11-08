// Top bar: workspaces on the left, media and clock in the center,
// system modules on the right.
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
    color: "transparent"            // the visible shape is the Rectangle below

    // Hyprland matches this name in hl.layer_rule to blur behind the bar.
    WlrLayershell.namespace: "quickshell-bar"

    // Caffeine: the bars are always mapped, so their inhibitors hold off hypridle.
    IdleInhibitor {
        window: bar
        enabled: Caffeine.active
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        // Glass in browsing; almost opaque in focus, where Hyprland also drops the blur.
        // Only the alpha animates here: Theme already fades the color itself.
        property real glass: ModeState.focus ? 0.92 : 0.55
        Behavior on glass { NumberAnimation { duration: Theme.colorFade } }
        color: Qt.alpha(Theme.surface, glass)
        border.width: 1
        border.color: Qt.alpha(Theme.outlineVariant, 0.6)

        Workspaces {
            anchors { left: parent.left; leftMargin: 5; verticalCenter: parent.verticalCenter }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: Theme.spacing

            Media {}
            Clock {}
        }

        StatusModules {
            window: bar
            anchors { right: parent.right; rightMargin: 5; verticalCenter: parent.verticalCenter }
        }
    }
}
