// Wi-Fi view: networks scanned while open, connected and saved first, then by signal.
import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

ColumnLayout {
    id: page

    signal back
    property bool showBack: true            // hidden when the view is opened on its own from the bar

    readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var networks: (device?.networks.values ?? [])
        .filter(n => n.name !== "")                         // hidden networks
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))

    spacing: 10

    // Scan only while this view is visible.
    onVisibleChanged: if (device) device.scannerEnabled = visible && Networking.wifiEnabled

    RowLayout {
        spacing: 8

        MaterialIcon {
            icon: "arrow_back"
            visible: page.showBack
            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: page.back() }
        }
        Label {
            text: "Wi-Fi"
            font.weight: Font.DemiBold
            font.pixelSize: Theme.fontSize + 2
            Layout.fillWidth: true
        }
        MaterialIcon {         // spins while scanning
            icon: "sync"
            color: Theme.surfaceTextMuted
            visible: page.device?.scannerEnabled ?? false
            RotationAnimation on rotation {
                running: page.device?.scannerEnabled ?? false
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

            Repeater {
                model: page.networks
                WifiNetworkRow { required property var modelData; network: modelData }
            }
            Label {
                visible: page.networks.length === 0
                text: page.device === null ? "No Wi-Fi adapter" : "Searching…"
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
            text: "Turn off Wi-Fi"
            color: Theme.error
        }
        MouseArea {
            id: offArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (page.device) page.device.scannerEnabled = false;
                Networking.wifiEnabled = false;
                page.back();
            }
        }
    }
}
