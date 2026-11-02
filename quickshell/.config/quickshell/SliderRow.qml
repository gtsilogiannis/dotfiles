// Icon, draggable track and percentage. Click or drag to set, scroll for ±5%.
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property string icon
    property real value: 0          // 0..1
    property bool available: true

    signal moved(real value)        // the new value chosen by the user

    spacing: 10
    opacity: available ? 1 : 0.4

    MaterialIcon { icon: root.icon; color: Theme.primary }

    Item {
        Layout.fillWidth: true
        implicitHeight: 24

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Qt.alpha(Theme.surfaceTextMuted, 0.25)

            Rectangle {
                width: track.width * root.value
                height: parent.height
                radius: 3
                color: Theme.primary
            }
        }

        Rectangle {     // handle
            x: Math.max(0, Math.min(track.width - width, track.width * root.value - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 8
            color: Theme.primary
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.available
            cursorShape: Qt.PointingHandCursor
            function choose(x) { root.moved(Math.max(0, Math.min(1, x / width))); }
            onPressed: mouse => choose(mouse.x)
            onPositionChanged: mouse => { if (pressed) choose(mouse.x); }
            onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }

    Label {
        text: `${Math.round(root.value * 100)}%`
        horizontalAlignment: Text.AlignRight
        Layout.preferredWidth: 40
    }
}
