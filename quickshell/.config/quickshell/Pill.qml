// Rounded container for one bar module. Children are laid out in a row
// and centered vertically; the whole pill reacts to hover, clicks and scroll.
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: pill

    default property alias content: row.data
    property bool interactive: true

    signal clicked(var mouse)                 // mouse.button tells which button
    signal scrolled(int delta)                // > 0 up, < 0 down

    readonly property bool hovered: area.containsMouse

    implicitWidth: row.implicitWidth + 20
    implicitHeight: Theme.pillHeight
    radius: height / 2
    color: Qt.alpha(Theme.surfaceContainerHigh, interactive && hovered ? 0.9 : 0.55)
    Behavior on color { ColorAnimation { duration: 150 } }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: pill.interactive
        enabled: pill.interactive
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => pill.clicked(mouse)
        onWheel: wheel => pill.scrolled(wheel.angleDelta.y)
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacing
    }
}
