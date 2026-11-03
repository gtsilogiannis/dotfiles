// One window inside an overview tile: placed and sized from its Hyprland geometry,
// with a frozen preview (captured when the overview opens and again when the window
// moves or resizes). Hover shows the app icon and the title.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

Item {
    id: root

    required property var toplevel          // HyprlandToplevel
    required property Item tile             // the workspace tile (scaleFactor, mon, globalIndex)
    required property var overview          // Overview.qml

    readonly property var ipc: toplevel?.lastIpcObject ?? ({})
    // at / size arrive from IPC as Qt sequences, not JS arrays (Array.isArray is false), so check the length.
    readonly property bool placed: tile !== null && ipc.at?.length === 2 && ipc.size?.length === 2 && (tile.mon ?? null) !== null
    readonly property string appId: Apps.idOf(toplevel)
    readonly property string iconSource: Apps.icon(appId)
    readonly property bool dimmed: root.overview.query !== "" && !root.overview.matches.includes(toplevel)
    readonly property bool firstMatch: root.overview.query !== "" && root.overview.matches[0] === toplevel
    readonly property string geometryKey: placed ? `${ipc.at}|${ipc.size}` : ""

    visible: placed
    // Whole pixels: a texture drawn at a fractional offset is resampled and looks soft.
    x: placed ? Math.round((ipc.at[0] - tile.mon.x) * tile.scaleFactor) : 0
    y: placed ? Math.round((ipc.at[1] - tile.mon.y) * tile.scaleFactor) : 0
    width: placed ? Math.max(8, Math.round(ipc.size[0] * tile.scaleFactor)) : 0
    height: placed ? Math.max(8, Math.round(ipc.size[1] * tile.scaleFactor)) : 0
    z: ipc.floating ? 2 : 1                 // floating windows above tiled ones, as on screen
    opacity: root.overview.dragged === toplevel ? 0.35 : dimmed ? 0.25 : 1

    // Retiling after a move or close: take a new picture at the new size.
    onGeometryKeyChanged: if (root.overview.visible && preview.hasContent) preview.captureFrame()

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: Qt.alpha(Theme.surfaceContainer, 0.9)
        clip: true

        // Downscaling a window 3-4x: render it into a texture at 4x the preview size,
        // then halve twice. Each exact 2:1 step with linear filtering averages 2x2
        // pixels (a box filter), which keeps text sharp. Mipmaps blend two levels and
        // blur; a single bilinear shrink drops pixels and looks jagged.
        Item {
            anchors.fill: parent
            layer.enabled: preview.hasContent
            layer.smooth: true
            layer.textureSize: Qt.size(root.width * 2, root.height * 2)

            Item {
                anchors.fill: parent
                layer.enabled: preview.hasContent
                layer.smooth: true
                layer.textureSize: Qt.size(root.width * 4, root.height * 4)

                // Capture only while the overview is open; null frees the buffer when it closes.
                ScreencopyView {
                    id: preview
                    anchors.fill: parent
                    smooth: true
                    captureSource: root.overview.visible ? root.toplevel?.wayland ?? null : null
                    live: false
                }
            }
        }

        // App icon in the centre, only on hover (and while the preview is not ready yet).
        Rectangle {
            anchors.centerIn: parent
            visible: mouse.containsMouse || !preview.hasContent
            readonly property real size: Math.max(18, Math.min(28, Math.min(root.width, root.height) * 0.25))
            width: size
            height: size
            radius: size / 4
            color: Qt.alpha(Theme.surface, 0.75)

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
        visible: mouse.containsMouse && root.overview.dragged === null
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
        cursorShape: root.overview.dragged === root.toplevel ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        property point pressedAt
        property bool dragging: false

        onEntered: if (root.overview.dragged === null) root.overview.selected = root.tile.globalIndex
        onPressed: mouse => {
            pressedAt = Qt.point(mouse.x, mouse.y);
            dragging = false;
        }
        // A left press that moves more than 6 px becomes a drag.
        onPositionChanged: mouse => {
            if (!(mouse.buttons & Qt.LeftButton)) return;
            if (!dragging && Math.hypot(mouse.x - pressedAt.x, mouse.y - pressedAt.y) > 6) dragging = true;
            if (dragging) root.overview.dragMove(root.toplevel, mapToItem(root.overview.dragLayer, mouse.x, mouse.y));
        }
        onReleased: mouse => {
            if (dragging) {
                dragging = false;
                root.overview.dragEnd();
            } else if (mouse.button === Qt.MiddleButton) {
                root.overview.closeWindow(root.toplevel);
            } else if (mouse.button === Qt.LeftButton) {
                root.overview.focusWindow(root.toplevel);
            }
        }
    }
}
