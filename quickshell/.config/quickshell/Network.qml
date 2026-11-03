// Network state as an icon only (signal strength, wired or offline), to keep the bar
// narrow. Click: Wi-Fi page of the control center, with the network name and the list.
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
    value: ""
    accent: wifi === null && wired === null ? Theme.error : Theme.primary

    onClicked: ControlCenterState.openPage("wifi")
}
