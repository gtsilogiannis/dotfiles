// Wi-Fi name and signal, or wired. Click: Wi-Fi list in the control center.
import QtQuick
import Quickshell.Networking

Stat {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var network: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property real strength: network?.signalStrength ?? 1

    icon: wired ? "lan"
        : wifi === null ? "signal_wifi_off"
        : strength > 0.75 ? "signal_wifi_4_bar"
        : strength > 0.5 ? "network_wifi_3_bar"
        : strength > 0.25 ? "network_wifi_2_bar"
        : "network_wifi_1_bar"
    // SSID shortened to keep the bar compact; the interface name if the SSID is not known yet.
    value: wired ? "wired"
         : wifi === null ? "offline"
         : (network?.name ?? wifi.name).slice(0, 12)
    accent: wifi === null && wired === null ? Theme.error : Theme.primary

    onClicked: ControlCenterState.openPage("wifi")
}
