// Wallpaper picker (SUPER + W): thumbnails of ~/Pictures/wallpapers (subfolders
// included), the current one marked. Enter / click applies it with
// scripts/set-wallpaper.sh (awww + matugen colors).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

MenuWindow {
    id: root

    menuName: "wallpaper"
    readonly property int columns: 4
    readonly property int cellWidth: 216
    readonly property int cellHeight: 150
    panelWidth: columns * cellWidth + 28
    panelHeight: 3 * cellHeight + 110

    readonly property string folder: Quickshell.env("HOME") + "/Pictures/wallpapers"
    property string current: ""
    property var files: []

    function apply(path) {
        Quickshell.execDetached([Quickshell.shellDir + "/scripts/set-wallpaper.sh", path]);
        MenuState.close();
    }

    onOpened: {
        scan.running = true;
        grid.forceActiveFocus();
    }

    // First line: the current wallpaper (written by set-wallpaper.sh), then the files.
    Process {
        id: scan
        command: ["sh", "-c",
            "cat \"$HOME/.cache/current_wallpaper.path\" 2>/dev/null || echo; " +
            "find \"$1\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort",
            "sh", root.folder]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n");
                root.current = lines[0].trim();
                root.files = lines.slice(1).filter(l => l !== "");
                const i = root.files.indexOf(root.current);
                grid.currentIndex = i >= 0 ? i : 0;
                grid.positionViewAtIndex(grid.currentIndex, GridView.Contain);
            }
        }
    }

    ColumnLayout {
        anchors { fill: parent; margins: 14 }
        spacing: 10

        RowLayout {
            spacing: 10
            MaterialIcon { icon: "wallpaper"; color: Theme.primary; font.pixelSize: 22 }
            Label {
                text: "Wallpapers"
                font.weight: Font.DemiBold
                font.pixelSize: Theme.fontSize + 2
                Layout.fillWidth: true
            }
            Label {
                text: root.files[grid.currentIndex]?.slice(root.folder.length + 1) ?? ""
                color: Theme.surfaceTextMuted
                elide: Text.ElideMiddle
                Layout.maximumWidth: 420
            }
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: root.cellWidth
            cellHeight: root.cellHeight
            model: root.files
            highlightMoveDuration: 0
            keyNavigationWraps: true

            Keys.onEscapePressed: MenuState.close()
            Keys.onReturnPressed: if (root.files.length > 0) root.apply(root.files[currentIndex])
            Keys.onEnterPressed: if (root.files.length > 0) root.apply(root.files[currentIndex])

            delegate: Item {
                id: cell
                required property string modelData
                required property int index
                readonly property bool selected: GridView.isCurrentItem
                readonly property bool isCurrent: modelData === root.current

                width: root.cellWidth
                height: root.cellHeight

                Rectangle {
                    anchors { fill: parent; margins: 6 }
                    radius: 14
                    color: Qt.alpha(Theme.surfaceContainerHigh, 0.7)
                    border.width: cell.selected ? 3 : cell.isCurrent ? 1 : 0
                    border.color: Theme.primary
                    clip: true

                    Image {
                        anchors { fill: parent; margins: cell.selected ? 3 : 1 }
                        source: "file://" + cell.modelData
                        sourceSize.width: 400            // decode small: 4K files stay cheap
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    Rectangle {      // "current" badge
                        visible: cell.isCurrent
                        anchors { top: parent.top; right: parent.right; margins: 8 }
                        width: 24; height: 24; radius: 12
                        color: Theme.primary
                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: "check"
                            color: Theme.primaryText
                            font.pixelSize: 16
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: grid.currentIndex = cell.index
                    onClicked: root.apply(cell.modelData)
                }
            }

            Label {
                anchors.centerIn: parent
                visible: root.files.length === 0 && !scan.running
                text: `No images in ${root.folder}`
                color: Theme.surfaceTextMuted
            }
        }

        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: Theme.surfaceTextMuted
            font.pixelSize: Theme.fontSize - 2
            text: "← ↑ → ↓: select   ·   Enter: apply (colors follow)   ·   Esc: close"
        }
    }
}
