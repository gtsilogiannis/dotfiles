// One bar module as its own glass island. Children are laid out in a row
// and centered vertically; the whole pill reacts to hover, clicks and scroll.
import QtQuick
import QtQuick.Layouts

Glass {
    id: pill

    default property alias content: row.data
    property bool interactive: true

    signal clicked(var mouse)                 // mouse.button tells which button
    signal scrolled(int delta)                // > 0 up, < 0 down

    readonly property bool hovered: area.containsMouse

    implicitWidth: row.implicitWidth + 22

    // Hover: a lighter layer over the glass. Its opacity animates, not the glass color,
    // which already follows the theme fade.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1                    // inside the outline
        radius: height / 2
        color: Theme.surfaceContainerHigh
        opacity: pill.interactive && pill.hovered ? 0.7 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

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
