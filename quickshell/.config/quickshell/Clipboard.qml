// Clipboard history from cliphist (ALT + ,). Newest first; typing filters the
// text entries. Enter / click copies the entry back, Delete removes it.
// Images show a thumbnail, decoded on demand into $XDG_RUNTIME_DIR.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

MenuWindow {
    id: root

    menuName: "clipboard"
    panelWidth: 620
    panelHeight: 540

    readonly property string thumbDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/qs-clipboard"

    // cliphist list: one "id<TAB>preview" line per entry, newest first.
    property var entries: []
    readonly property var shown: {
        const q = input.text.trim().toLowerCase();
        return q === "" ? entries : entries.filter(e => !e.image && e.preview.toLowerCase().includes(q));
    }

    // "[[ binary data 52 KiB png 800x600 ]]" -> image entry
    function parse(text) {
        return text.split("\n").filter(l => l !== "").map(line => {
            const tab = line.indexOf("\t");
            const preview = line.slice(tab + 1);
            const m = /^\[\[ binary data (.+?) (png|jpe?g|webp|bmp|gif)(?: (\d+x\d+))? \]\]$/.exec(preview);
            return { id: line.slice(0, tab), preview: preview, image: m !== null,
                     ext: m?.[2] ?? "", info: m ? `${m[2].toUpperCase()} ${m[3] ?? ""}  ·  ${m[1]}` : "" };
        });
    }

    // The id followed by a tab is a line that "cliphist decode / delete" accept on stdin.
    function copy(entry) {
        Quickshell.execDetached(["sh", "-c", "printf '%s\\t\\n' \"$1\" | cliphist decode | wl-copy", "sh", entry.id]);
        MenuState.close();
    }

    function remove(entry) {
        Quickshell.execDetached(["sh", "-c", "printf '%s\\t\\n' \"$1\" | cliphist delete", "sh", entry.id]);
        root.entries = root.entries.filter(e => e.id !== entry.id);
    }

    onOpened: {
        input.text = "";
        list.currentIndex = 0;
        lister.running = true;
        input.forceActiveFocus();
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = root.parse(this.text);
                list.currentIndex = 0;
            }
        }
    }

    ColumnLayout {
        anchors { fill: parent; margins: 14 }
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 14
            color: Qt.alpha(Theme.surfaceContainerHigh, 0.7)

            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                spacing: 10

                MaterialIcon { icon: "content_paste"; color: Theme.primary; font.pixelSize: 22 }

                TextInput {
                    id: input
                    Layout.fillWidth: true
                    color: Theme.surfaceText
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.primaryText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 3
                    clip: true

                    onTextChanged: list.currentIndex = 0

                    Keys.onEscapePressed: MenuState.close()
                    Keys.onReturnPressed: if (list.currentItem) root.copy(list.currentItem.modelData)
                    Keys.onEnterPressed: if (list.currentItem) root.copy(list.currentItem.modelData)
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onDeletePressed: event => {
                        // Delete with an empty field removes the selected entry; with text it edits the text.
                        if (input.text === "" && list.currentItem) root.remove(list.currentItem.modelData);
                        else event.accepted = false;
                    }

                    Label {
                        visible: input.text === ""
                        text: "Search clipboard history"
                        color: Theme.surfaceTextMuted
                        font.pixelSize: Theme.fontSize + 1
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Label {
                    text: `${root.shown.length}`
                    color: Theme.surfaceTextMuted
                }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.shown
            highlightMoveDuration: 0
            cacheBuffer: 0                 // decode only the thumbnails on screen

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem
                readonly property string thumb: modelData.image ? `${root.thumbDir}/${modelData.id}.${modelData.ext}` : ""
                property bool thumbReady: false

                width: ListView.view.width
                height: modelData.image ? 76 : 40
                radius: 12
                color: current ? Qt.alpha(Theme.primary, 0.22) : "transparent"

                // Decode the image once; later openings reuse the file.
                Process {
                    running: row.modelData.image
                    command: ["sh", "-c",
                        "mkdir -p \"$1\" && { [ -s \"$2\" ] || printf '%s\\t\\n' \"$3\" | cliphist decode > \"$2\"; }",
                        "sh", root.thumbDir, row.thumb, row.modelData.id]
                    onExited: code => row.thumbReady = code === 0
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    spacing: 12

                    Rectangle {
                        visible: row.modelData.image
                        implicitWidth: 96
                        implicitHeight: 60
                        radius: 8
                        color: Qt.alpha(Theme.surfaceContainerHigh, 0.8)
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: row.thumbReady ? "file://" + row.thumb : ""
                            sourceSize.width: 192
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: row.modelData.image ? row.modelData.info : row.modelData.preview
                        color: row.modelData.image ? Theme.surfaceTextMuted : Theme.surfaceText
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    MaterialIcon {
                        visible: row.current
                        icon: "delete"
                        color: delArea.containsMouse ? Theme.error : Theme.surfaceTextMuted
                        MouseArea {
                            id: delArea
                            anchors { fill: parent; margins: -6 }
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.remove(row.modelData)
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: list.currentIndex = row.index
                    onClicked: root.copy(row.modelData)
                }
            }

            Label {
                anchors.centerIn: parent
                visible: root.shown.length === 0 && !lister.running
                text: root.entries.length === 0 ? "Clipboard history is empty" : "Nothing matches"
                color: Theme.surfaceTextMuted
            }
        }

        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: Theme.surfaceTextMuted
            font.pixelSize: Theme.fontSize - 2
            text: "↑ ↓: select   ·   Enter: copy   ·   Delete: remove   ·   Esc: close"
        }
    }
}
