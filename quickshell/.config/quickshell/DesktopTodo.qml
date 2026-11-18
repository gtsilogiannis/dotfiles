// To-do card on the depth desktop. The list is a Markdown checklist in
// $XDG_STATE_HOME/desktop/todo.md, read live and editable anywhere:
//   - [ ] open task
//   - [x] done task
// Other lines are kept but not shown. Click a box to tick it, + to add a task,
// the sweep icon to drop the ticked ones.
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property Item backdrop             // the wallpaper Image of the desktop layer
    property bool allowEditing: true
    property bool editing: false
    readonly property int maxShown: 7

    readonly property string path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/desktop/todo.md"
    property var lines: []                      // every line of the file
    // Checklist lines only: { line: index in lines, done, text }.
    readonly property var tasks: lines.reduce((list, l, i) => {
        const m = /^\s*[-*] \[([ xX])\] (.*)$/.exec(l);
        if (m) list.push({ line: i, done: m[1] !== " ", text: m[2] });
        return list;
    }, [])
    readonly property int openCount: tasks.filter(t => !t.done).length
    readonly property int doneCount: tasks.length - openCount
    // Open tasks first, in file order, then the ticked ones.
    readonly property var shownTasks: tasks.filter(t => !t.done).concat(tasks.filter(t => t.done)).slice(0, maxShown)

    readonly property int pad: 14

    implicitWidth: 252
    implicitHeight: column.implicitHeight + 2 * pad

    onAllowEditingChanged: if (!allowEditing) editing = false
    onEditingChanged: {
        entry.text = "";
        if (editing) Qt.callLater(() => entry.forceActiveFocus());
    }

    function write(newLines) {
        root.lines = newLines;                  // shown at once; the file watch confirms it
        file.setText(newLines.length ? newLines.join("\n") + "\n" : "");
    }

    function toggle(task) {
        const l = root.lines.slice();
        l[task.line] = l[task.line].replace(/\[[ xX]\]/, task.done ? "[ ]" : "[x]");
        root.write(l);
    }

    function add(text) {
        const t = text.trim();
        if (t.length > 0) root.write(root.lines.concat(["- [ ] " + t]));
        root.editing = false;
    }

    function clearDone() {
        const doneLines = new Set(root.tasks.filter(t => t.done).map(t => t.line));
        root.write(root.lines.filter((_, i) => !doneLines.has(i)));
    }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const t = text().replace(/\n$/, "");
            root.lines = t.length ? t.split("\n") : [];
        }
        onLoadFailed: root.lines = []           // no file yet: empty list, created on the first add
    }

    DesktopGlass { backdrop: root.backdrop }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad
        spacing: 6

        Item {
            width: parent.width
            height: 24

            Label {
                id: title
                x: 4
                anchors.verticalCenter: parent.verticalCenter
                text: "To-do"
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }
            Label {
                anchors.left: title.right
                anchors.leftMargin: 8
                anchors.baseline: title.baseline
                text: root.openCount > 0 ? root.openCount + " left" : ""
                font.pixelSize: 12
                color: Theme.surfaceTextMuted
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                MaterialIcon {
                    visible: root.doneCount > 0
                    icon: "delete_sweep"
                    font.pixelSize: 20
                    color: Theme.surfaceTextMuted
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearDone()
                    }
                }
                MaterialIcon {
                    icon: root.editing ? "close" : "add"
                    font.pixelSize: 22
                    color: Theme.primary
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.editing = !root.editing && root.allowEditing
                    }
                }
            }
        }

        Label {
            visible: root.tasks.length === 0 && !root.editing
            x: 4
            text: "Nothing to do"
            font.pixelSize: 13
            color: Theme.surfaceTextMuted
        }

        Repeater {
            model: root.shownTasks

            Item {
                id: row
                required property var modelData
                width: column.width
                height: Math.max(box.implicitHeight, label.implicitHeight) + 2

                MaterialIcon {
                    id: box
                    y: 1
                    icon: row.modelData.done ? "check_circle" : "radio_button_unchecked"
                    font.pixelSize: 20
                    color: row.modelData.done ? Theme.surfaceTextMuted : Theme.primary
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggle(row.modelData)
                    }
                }
                Label {
                    id: label
                    anchors.left: box.right
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    y: Math.round((box.implicitHeight - implicitHeight) / 2) + 1
                    text: row.modelData.text
                    font.pixelSize: 13
                    font.strikeout: row.modelData.done
                    color: row.modelData.done ? Theme.surfaceTextMuted : Theme.surfaceText
                    elide: Text.ElideRight
                }
            }
        }

        Label {
            visible: root.tasks.length > root.maxShown
            x: 32
            text: "+" + (root.tasks.length - root.maxShown) + " more"
            font.pixelSize: 12
            color: Theme.surfaceTextMuted
        }

        Rectangle {
            visible: root.editing
            width: column.width
            height: 30
            radius: Theme.radius
            color: Qt.alpha(Theme.surfaceContainerHigh, 0.6)
            border.width: 1
            border.color: Qt.alpha(Theme.primary, 0.6)

            TextInput {
                id: entry
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.surfaceText
                selectionColor: Theme.primary
                selectedTextColor: Theme.primaryText
                font.family: Theme.fontFamily
                font.pixelSize: 13
                clip: true
                Keys.onReturnPressed: root.add(text)
                Keys.onEnterPressed: root.add(text)
                Keys.onEscapePressed: root.editing = false
            }
            Label {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: entry.text.length === 0
                text: "New task"
                font.pixelSize: 13
                color: Theme.surfaceTextMuted
            }
        }
    }
}
