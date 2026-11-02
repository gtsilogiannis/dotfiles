// Battery: the charge level drawn inside a battery outline, with the percentage
// on top of it. A bolt marks charging; a plug marks AC power while charging is
// held back (conservation mode keeps the charge near 80%).
import QtQuick
import Quickshell.Services.UPower

Pill {
    id: root

    // UPower's aggregate device; percentage is 0..1 in Quickshell.
    readonly property var device: UPower.displayDevice
    readonly property real level: Math.max(0, Math.min(1, device.percentage))
    readonly property int percent: Math.round(level * 100)
    readonly property bool plugged: !UPower.onBattery
    readonly property bool charging: device.state === UPowerDeviceState.Charging
    // Warnings only matter on battery.
    readonly property color accent: !plugged && percent <= 15 ? Theme.error
                                  : !plugged && percent <= 30 ? Theme.tertiary
                                  : Theme.primary

    interactive: false
    visible: device.ready

    Item {
        implicitWidth: shell.width + nub.width + 1
        implicitHeight: shell.height

        Rectangle {
            id: shell
            width: 27
            height: 15
            radius: 4
            color: "transparent"
            border.width: 1.5
            border.color: root.accent

            Rectangle {     // charge level
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 2.5 }
                width: (shell.width - 5) * root.level
                radius: 2
                color: Qt.alpha(root.accent, 0.45)
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }

            Text {
                anchors.centerIn: parent
                text: root.percent
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }

        Rectangle {         // positive terminal
            id: nub
            anchors { left: shell.right; leftMargin: 1; verticalCenter: shell.verticalCenter }
            width: 2
            height: 6
            radius: 1
            color: root.accent
        }
    }

    MaterialIcon {
        visible: root.plugged
        icon: root.charging ? "bolt" : "power"
        filled: true
        color: root.accent
        font.pixelSize: 14
    }
}
