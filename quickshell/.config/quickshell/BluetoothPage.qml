// Bluetooth view of the control center: saved devices, nearby devices
// (scanned while the view is open) and a button to turn Bluetooth off.
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page

    required property var adapter

    signal back

    readonly property var devices: adapter?.devices.values ?? []
    readonly property var saved: devices.filter(d => d.paired || d.bonded)
    // New devices that announce a name (nameless ones show only their address).
    readonly property var nearby: devices.filter(d => !(d.paired || d.bonded) && d.deviceName !== "")

    spacing: 10

    // Scan only while this view is visible.
    onVisibleChanged: if (adapter && adapter.enabled) adapter.discovering = visible

    RowLayout {
        spacing: 8

        MaterialIcon {
            icon: "arrow_back"
            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: page.back() }
        }
        Label {
            text: "Bluetooth"
            font.weight: Font.DemiBold
            font.pixelSize: Theme.fontSize + 2
            Layout.fillWidth: true
        }
        MaterialIcon {         // spins while scanning
            icon: "sync"
            color: Theme.surfaceTextMuted
            visible: page.adapter?.discovering ?? false
            RotationAnimation on rotation {
                running: page.adapter?.discovering ?? false
                from: 0; to: -360; duration: 1500; loops: Animation.Infinite
            }
        }
    }

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: list.implicitHeight
        clip: true

        ColumnLayout {
            id: list
            width: parent.width
            spacing: 6

            Label {
                text: "My devices"
                color: Theme.surfaceTextMuted
                visible: page.saved.length > 0
            }
            Repeater {
                model: page.saved
                BluetoothDeviceRow { required property var modelData; device: modelData }
            }

            Label {
                text: "Other devices"
                color: Theme.surfaceTextMuted
                Layout.topMargin: 8
            }
            Repeater {
                model: page.nearby
                BluetoothDeviceRow { required property var modelData; device: modelData }
            }
            Label {
                visible: page.nearby.length === 0
                text: "Searching…"
                color: Theme.surfaceTextMuted
                font.pixelSize: Theme.fontSize - 1
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 40
        radius: 20
        color: offArea.containsMouse ? Qt.alpha(Theme.error, 0.3) : Qt.alpha(Theme.error, 0.15)

        Label {
            anchors.centerIn: parent
            text: "Turn off Bluetooth"
            color: Theme.error
        }
        MouseArea {
            id: offArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                page.adapter.discovering = false;
                page.adapter.enabled = false;
                page.back();
            }
        }
    }
}
