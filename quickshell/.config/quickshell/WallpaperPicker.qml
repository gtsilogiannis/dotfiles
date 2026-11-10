// Wallpaper picker (SUPER + W): thumbnails of ~/Pictures/wallpapers in one tab
// per folder (static, depth and video in browsing mode, focus in focus mode),
// the current one marked. Enter / click applies it with
// scripts/set-wallpaper.sh (awww or mpvpaper + matugen colors).
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
    panelHeight: 3 * cellHeight + 154

    readonly property string folder: Quickshell.env("HOME") + "/Pictures/wallpapers"
    readonly property var tabs: ModeState.focus ? ["focus"] : ["static", "depth", "video"]
    readonly property var tabLabels: ({ "static": "Static", "depth": "Depth", "video": "Video", "focus": "Focus" })
    readonly property var tabIcons: ({ "static": "image", "depth": "layers", "video": "movie", "focus": "center_focus_strong" })

    property string current: ""
    property string tab: "static"
    property var files: []          // { type, path, thumb } from scripts/list-wallpapers.sh
    readonly property var shown: files.filter(f => f.type === root.tab)

    function count(type) {
        return files.filter(f => f.type === type).length;
    }

    // Opens a tab with the current wallpaper selected when it is in there.
    function selectTab(name) {
        tab = name;
        const i = shown.findIndex(f => f.path === current);
        grid.currentIndex = i >= 0 ? i : 0;
        grid.positionViewAtIndex(grid.currentIndex, GridView.Contain);
    }

    function cycleTab(step) {
        const i = tabs.indexOf(tab);
        selectTab(tabs[(i + step + tabs.length) % tabs.length]);
    }

    function apply(path) {
        Quickshell.execDetached([Quickshell.shellDir + "/scripts/set-wallpaper.sh", path]);
        MenuState.close();
    }

    onOpened: {
        scan.running = true;
        grid.forceActiveFocus();
    }

    // The first run also makes the video thumbnails, which takes a few seconds.
    Process {
        id: scan
        command: [Quickshell.shellDir + "/scripts/list-wallpapers.sh", root.folder]
        stdout: StdioCollector {
            onStreamFinished: {
                let current = "";
                const list = [];
                for (const line of this.text.split("\n")) {
                    const part = line.split("\t");
                    if (part[0] === "current")
                        current = part[1] ?? "";
                    else if (part.length >= 3)
                        list.push({ type: part[0], path: part[1], thumb: part[2] });
                }
                root.current = current;
                root.files = list;
                const now = list.find(f => f.path === current);
                root.selectTab(now && root.tabs.includes(now.type) ? now.type : root.tabs[0]);
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
                text: root.shown[grid.currentIndex]?.path.slice(root.folder.length + 1) ?? ""
                color: Theme.surfaceTextMuted
                elide: Text.ElideMiddle
                Layout.maximumWidth: 420
            }
        }

        RowLayout {
            spacing: 8

            Repeater {
                model: root.tabs

                Rectangle {
                    id: chip
                    required property string modelData
                    readonly property bool active: modelData === root.tab

                    implicitWidth: chipRow.implicitWidth + 24
                    implicitHeight: 30
                    radius: 15
                    color: active ? Qt.alpha(Theme.primary, 0.25)
                         : chipMouse.containsMouse ? Qt.alpha(Theme.surfaceContainerHigh, 0.9)
                         : Qt.alpha(Theme.surfaceContainerHigh, 0.5)
                    border.width: active ? 1 : 0
                    border.color: Theme.primary

                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 6
                        MaterialIcon {
                            icon: root.tabIcons[chip.modelData]
                            color: chip.active ? Theme.primary : Theme.surfaceTextMuted
                            font.pixelSize: 16
                        }
                        Label {
                            text: root.tabLabels[chip.modelData]
                            color: chip.active ? Theme.surfaceText : Theme.surfaceTextMuted
                        }
                        Label {
                            text: root.count(chip.modelData)
                            color: Theme.surfaceTextMuted
                            font.family: Theme.monoFamily
                            font.pixelSize: Theme.fontSize - 1
                        }
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectTab(chip.modelData)
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: root.cellWidth
            cellHeight: root.cellHeight
            model: root.shown
            highlightMoveDuration: 0
            keyNavigationWraps: true

            Keys.onEscapePressed: MenuState.close()
            Keys.onReturnPressed: if (root.shown.length > 0) root.apply(root.shown[currentIndex].path)
            Keys.onEnterPressed: if (root.shown.length > 0) root.apply(root.shown[currentIndex].path)
            Keys.onTabPressed: root.cycleTab(1)
            Keys.onBacktabPressed: root.cycleTab(-1)

            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                readonly property bool selected: GridView.isCurrentItem
                readonly property bool isCurrent: modelData.path === root.current

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
                        visible: cell.modelData.thumb !== ""
                        source: cell.modelData.thumb !== "" ? "file://" + cell.modelData.thumb : ""
                        sourceSize.width: 400            // decode small: 4K files stay cheap
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    Rectangle {      // type badge: moving or layered wallpapers
                        visible: cell.modelData.type === "video" || cell.modelData.type === "depth"
                        anchors { left: parent.left; bottom: parent.bottom; margins: 8 }
                        width: 24; height: 24; radius: 12
                        color: Qt.alpha(Theme.surface, 0.75)
                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: cell.modelData.type === "video" ? "play_arrow" : "layers"
                            color: Theme.surfaceText
                            font.pixelSize: 16
                        }
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
                    onClicked: root.apply(cell.modelData.path)
                }
            }

            Label {
                anchors.centerIn: parent
                visible: root.shown.length === 0
                text: scan.running ? "Loading wallpapers…" : `No wallpapers in ${root.folder}/${root.tab}`
                color: Theme.surfaceTextMuted
            }
        }

        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: Theme.surfaceTextMuted
            font.pixelSize: Theme.fontSize - 2
            text: (root.tabs.length > 1 ? "Tab: next folder   ·   " : "")
                + "← ↑ → ↓: select   ·   Enter: apply (colors follow)   ·   Esc: close"
        }
    }
}
