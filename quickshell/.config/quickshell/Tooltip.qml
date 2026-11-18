// Hover hint under a bar item, in its own popup: the bar window would clip it.
import QtQuick
import Quickshell

PopupWindow {
    id: tip

    required property Item target           // the item the hint belongs to
    property string text
    property bool hovered: false            // the target sets this from its MouseArea

    anchor.item: target
    anchor.edges: Edges.Bottom              // attach to the bottom middle of the item
    anchor.gravity: Edges.Bottom            // and grow downwards; it slides back on screen if needed

    implicitWidth: box.implicitWidth
    implicitHeight: box.implicitHeight + 10 // transparent gap below the bar
    color: "transparent"
    visible: delay.done && tip.text !== ""

    // Show after a short hover only, so passing over the bar does not flash hints.
    Timer {
        id: delay
        property bool done: false
        interval: 400
        running: tip.hovered && !done
        onTriggered: done = true
    }
    onHoveredChanged: if (!hovered) delay.done = false

    Rectangle {
        id: box
        y: 10
        implicitWidth: label.implicitWidth + 20
        implicitHeight: label.implicitHeight + 12
        radius: 8
        color: Qt.alpha(Theme.surface, 0.92)
        border.width: 1
        border.color: Qt.alpha(Theme.outlineVariant, 0.6)

        Label {
            id: label
            anchors.centerIn: parent
            text: tip.text
            font.pixelSize: Theme.fontSize - 1
        }
    }
}
