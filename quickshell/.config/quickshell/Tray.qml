// System tray (nm-applet, Spotify, Vesktop, ...). Left click: activate, right click: menu.
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Pill {
    id: root

    required property var window        // the bar, needed to place the menus

    // Hidden: covered by the control center, the media pill or the workspace icons.
    // Claude Desktop's item also ignores activation and its menu never opens.
    readonly property var items: SystemTray.items.values.filter(item => !/nm-applet|blueman|bluetooth|spotify|^claude_status_icon/i.test(item.id))

    interactive: false
    visible: items.length > 0

    Repeater {
        model: root.items

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
