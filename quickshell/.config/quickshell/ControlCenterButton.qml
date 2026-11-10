// One pill for the control center, as on iOS: network state and the bell side by side.
// Left click: control center (Wi-Fi and Bluetooth are inside it).
// Right click: Do Not Disturb.
import QtQuick
import Quickshell.Networking

Pill {
    id: root

    // Network: signal strength, wired or offline.
    readonly property var devices: Networking.devices.values
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var network: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property real strength: network?.signalStrength ?? 1

    // Notifications kept in the history.
    readonly property int count: NotificationService.history.length

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) NotificationService.dnd = !NotificationService.dnd;
        else ControlCenterState.toggle();
    }

    MaterialIcon {
        icon: root.wired ? "lan"
            : root.wifi === null ? "signal_wifi_off"
            : root.strength > 0.75 ? "signal_wifi_4_bar"
            : root.strength > 0.5 ? "network_wifi_3_bar"
            : root.strength > 0.25 ? "network_wifi_2_bar"
            : "network_wifi_1_bar"
        color: root.wifi === null && root.wired === null ? Theme.error : Theme.primary
    }

    MaterialIcon {
        icon: NotificationService.dnd ? "notifications_off"
            : root.count > 0 ? "notifications_unread"
            : "notifications"
        filled: root.count > 0 && !NotificationService.dnd
        color: NotificationService.dnd ? Theme.surfaceTextMuted : Theme.primary
    }
    Label {
        visible: root.count > 0
        text: root.count
        font.family: Theme.monoFamily
    }
}
