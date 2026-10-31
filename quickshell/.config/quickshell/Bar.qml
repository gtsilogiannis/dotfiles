// Top bar: workspaces on the left, clock in the center.
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

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Qt.alpha(Theme.surface, 0.55)
        border.width: 1
        border.color: Qt.alpha(Theme.outlineVariant, 0.6)

        Workspaces {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
        }

        Clock {
            anchors.centerIn: parent
        }
    }
}
