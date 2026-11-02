// System tray (nm-applet, Spotify, Vesktop, ...). Left click: activate, right click: menu.
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Pill {
    id: root

    required property var window        // the bar, needed to place the menus

    interactive: false
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items.values

        IconImage {
            id: trayIcon
            required property var modelData
            implicitSize: 16
            source: modelData.icon
            mipmap: true

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    const item = trayIcon.modelData;
                    if (mouse.button === Qt.LeftButton && !item.onlyMenu) {
                        item.activate();
                    } else if (item.hasMenu) {
                        // Open the menu right below the icon, in bar window coordinates.
                        const p = trayIcon.mapToItem(null, 0, trayIcon.height + 6);
                        item.display(root.window, p.x, p.y);
                    }
                }
            }
        }
    }
}
