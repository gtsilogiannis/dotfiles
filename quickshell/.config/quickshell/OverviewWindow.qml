// One window inside an overview tile: placed and sized from its Hyprland geometry,
// with a frozen preview (captured when the overview opens and again when the window
// moves or resizes) and the app icon on top, so tiny previews stay recognisable.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

Item {
    id: root

    required property var toplevel          // HyprlandToplevel
    required property Item tile             // the workspace tile (scaleFactor, mon)
    required property var overview          // Overview.qml

    readonly property var ipc: toplevel?.lastIpcObject ?? ({})
    readonly property bool placed: Array.isArray(ipc.at) && Array.isArray(ipc.size) && tile.mon !== null
    readonly property string appId: Apps.idOf(toplevel)
    readonly property string iconSource: Apps.icon(appId)
    readonly property bool dimmed: overview.query !== "" && !overview.matches.includes(toplevel)
    readonly property bool firstMatch: overview.query !== "" && overview.matches[0] === toplevel
    readonly property string geometryKey: placed ? `${ipc.at}|${ipc.size}` : ""

    visible: placed
    x: placed ? (ipc.at[0] - tile.mon.x) * tile.scaleFactor : 0
    y: placed ? (ipc.at[1] - tile.mon.y) * tile.scaleFactor : 0
    width: placed ? Math.max(8, ipc.size[0] * tile.scaleFactor) : 0
    height: placed ? Math.max(8, ipc.size[1] * tile.scaleFactor) : 0
    z: ipc.floating ? 2 : 1                 // floating windows above tiled ones, as on screen
    opacity: overview.dragged === toplevel ? 0.35 : dimmed ? 0.25 : 1

    // Retiling after a move or close: take a new picture at the new size.
    onGeometryKeyChanged: if (overview.visible && preview.hasContent) preview.captureFrame()

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: Qt.alpha(Theme.surfaceContainer, 0.9)
        clip: true

        // The preview is drawn at twice the tile size into a mipmapped layer and scaled
        // down by half: a plain bilinear shrink of a full-size window looks jagged.
        Item {
            width: parent.width * 2
            height: parent.height * 2
            scale: 0.5
            transformOrigin: Item.TopLeft
            layer.enabled: preview.hasContent
            layer.smooth: true
            layer.mipmap: true

            // Capture only while the overview is open; null frees the buffer when it closes.
            ScreencopyView {
                id: preview
                anchors.fill: parent
                captureSource: root.overview.visible ? root.toplevel?.wayland ?? null : null
                live: false
            }
        }

        // App icon, centred; grows with the window but stays readable on tiny tiles.
        Rectangle {
            anchors.centerIn: parent
            readonly property real size: Math.max(22, Math.min(44, Math.min(root.width, root.height) * 0.4))
            width: size
            height: size
            radius: size / 4
            color: Qt.alpha(Theme.surface, preview.hasContent ? 0.55 : 0.9)

            IconImage {
                anchors.centerIn: parent
                implicitSize: parent.size * 0.72
                visible: root.iconSource !== ""
                source: root.iconSource
                mipmap: true
            }
            MaterialIcon {
                anchors.centerIn: parent
                visible: root.iconSource === ""
                icon: "apps"
                font.pixelSize: parent.size * 0.6
            }
        }
    }

    // Frame: primary on hover and on the first search match.
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: "transparent"
        border.width: mouse.containsMouse || root.firstMatch ? 2 : 1
        border.color: mouse.containsMouse || root.firstMatch ? Theme.primary : Qt.alpha(Theme.outlineVariant, 0.9)
    }

    // Title on hover.
    Rectangle {
        visible: mouse.containsMouse && overview.dragged === null
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 4 }
        height: 22
        radius: 6
        color: Qt.alpha(Theme.surface, 0.9)

        Label {
            anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
            text: root.toplevel?.title || Apps.name(root.appId)
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSize - 1
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: overview.dragged === root.toplevel ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        property point pressedAt
        property bool dragging: false

        onEntered: if (overview.dragged === null) overview.selected = root.tile.index
        onPressed: mouse => {
            pressedAt = Qt.point(mouse.x, mouse.y);
            dragging = false;
        }
        // A left press that moves more than 6 px becomes a drag.
        onPositionChanged: mouse => {
            if (!(mouse.buttons & Qt.LeftButton)) return;
            if (!dragging && Math.hypot(mouse.x - pressedAt.x, mouse.y - pressedAt.y) > 6) dragging = true;
            if (dragging) overview.dragMove(root.toplevel, mapToItem(overview.dragLayer, mouse.x, mouse.y));
        }
        onReleased: mouse => {
            if (dragging) {
                dragging = false;
                overview.dragEnd();
            } else if (mouse.button === Qt.MiddleButton) {
                overview.closeWindow(root.toplevel);
            } else if (mouse.button === Qt.LeftButton) {
                overview.focusWindow(root.toplevel);
            }
        }
    }
}
