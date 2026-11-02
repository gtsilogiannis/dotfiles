// Bell in the bar. Left click: control center, right click: Do Not Disturb.
import QtQuick

Stat {
    readonly property int count: NotificationService.history.length

    icon: NotificationService.dnd ? "notifications_off" : count > 0 ? "notifications_unread" : "notifications"
    filled: count > 0 && !NotificationService.dnd
    value: count > 0 ? String(count) : ""
    accent: NotificationService.dnd ? Theme.surfaceTextMuted : Theme.primary

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) NotificationService.dnd = !NotificationService.dnd;
        else ControlCenterState.toggle();
    }
}
