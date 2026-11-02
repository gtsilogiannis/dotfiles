// One Bluetooth device. Click: disconnect if connected, connect if paired,
// pair (then trust and connect) if new.
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

Rectangle {
    id: row

    required property var device

    readonly property int state_: device.state      // not "state": that name belongs to Item
    readonly property bool paired: device.paired || device.bonded

    // BlueZ icon names (freedesktop) -> Material Symbols.
    function iconFor(name) {
        if (/headset|headphone|audio/.test(name)) return "headphones";
        if (/mouse/.test(name)) return "mouse";
        if (/keyboard/.test(name)) return "keyboard";
        if (/phone/.test(name)) return "smartphone";
        if (/computer/.test(name)) return "computer";
        if (/gaming|joystick/.test(name)) return "sports_esports";
        return "bluetooth";
    }

    Layout.fillWidth: true
    implicitHeight: 52
    radius: 12
    color: area.containsMouse ? Qt.alpha(Theme.surfaceContainerHigh, 0.95) : Qt.alpha(Theme.surfaceContainerHigh, 0.6)

    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        spacing: 12

        MaterialIcon {
            icon: row.iconFor(row.device.icon)
            filled: row.device.connected
            color: row.device.connected ? Theme.primary : Theme.surfaceText
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                text: row.device.name || row.device.address
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Label {
                text: row.state_ === BluetoothDeviceState.Connecting ? "Connecting…"
                    : row.state_ === BluetoothDeviceState.Disconnecting ? "Disconnecting…"
                    : row.device.pairing ? "Pairing…"
                    : row.device.connected ? "Connected"
                    : row.paired ? "Not connected"
                    : "Tap to pair"
                color: row.device.connected ? Theme.primary : Theme.surfaceTextMuted
                font.pixelSize: Theme.fontSize - 1
            }
        }

        Label {         // e.g. AirPods battery, when the device reports it
            visible: row.device.connected && row.device.batteryAvailable
            text: `${Math.round(row.device.battery * 100)}%`
            color: Theme.surfaceTextMuted
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (row.device.connected) row.device.disconnect();
            else if (row.paired) row.device.connect();
            else if (!row.device.pairing) row.device.pair();
        }
    }

    // After a new pairing: remember the device and connect to it.
    Connections {
        target: row.device
        function onPairedChanged() {
            if (row.device.paired) {
                row.device.trusted = true;
                row.device.connect();
            }
        }
    }
}
