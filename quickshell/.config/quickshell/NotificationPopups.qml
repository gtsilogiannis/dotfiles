// Popups at the top center, below the bar, stacked newest first.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    // Same monitor as the control center: the one that has focus.
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors.top: true                       // only top: centered horizontally
    margins.top: Theme.gap * 2 + Theme.barHeight
    exclusionMode: ExclusionMode.Ignore     // does not push windows down
    implicitWidth: 420
    implicitHeight: column.implicitHeight
    color: "transparent"
    visible: NotificationService.popups.length > 0

    WlrLayershell.namespace: "quickshell-notifications"
    WlrLayershell.layer: WlrLayer.Overlay   // above fullscreen windows too

    Column {
        id: column
        width: parent.width
        spacing: Theme.spacing

        Repeater {
            model: NotificationService.popups

            NotificationCard {
                required property var modelData
                notification: modelData
                popup: true
                width: column.width
            }
        }
    }
}
