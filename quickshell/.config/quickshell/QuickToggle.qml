// Toggle tile: icon and label, filled with the accent color when on.
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: tile

    property string icon
    property string label
    property bool active: false
    property bool available: true

    signal clicked

    Layout.fillWidth: true
    implicitHeight: 64
    radius: 14
    opacity: available ? 1 : 0.4
    color: active ? Theme.primary
         : area.containsMouse ? Qt.alpha(Theme.surfaceContainerHigh, 0.95)
         : Qt.alpha(Theme.surfaceContainerHigh, 0.7)
    Behavior on color { ColorAnimation { duration: 150 } }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2

        MaterialIcon {
            icon: tile.icon
            filled: tile.active
            color: tile.active ? Theme.primaryText : Theme.surfaceText
            Layout.alignment: Qt.AlignHCenter
        }
        Label {
            text: tile.label
            color: tile.active ? Theme.primaryText : Theme.surfaceTextMuted
            font.pixelSize: Theme.fontSize - 1
            Layout.alignment: Qt.AlignHCenter
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: tile.available
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }
}
