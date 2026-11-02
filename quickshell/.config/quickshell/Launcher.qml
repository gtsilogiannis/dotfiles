// App launcher (SUPER + Space). Apps are always listed alphabetically; typing
// filters them. Two prefixes change what the field does:
//   >command   Enter runs it in kitty, Shift + Enter runs it in the background
//   =1+2*3     live result, Enter copies it to the clipboard
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "calc.js" as Calc

MenuWindow {
    id: root

    menuName: "launcher"
    panelWidth: 560
    panelHeight: 500

    // DesktopEntries.applications already leaves out Hidden / NoDisplay entries,
    // so the overrides in ~/.local/share/applications decide what is listed.
    readonly property var apps: [...DesktopEntries.applications.values]
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property string query: input.text
    readonly property string mode: query.startsWith(">") ? "run"
                                 : query.startsWith("=") ? "calc"
                                 : "apps"
    readonly property string term: (mode === "apps" ? query : query.slice(1)).trim()
    readonly property var results: mode !== "apps" ? []
        : term === "" ? apps
        : apps.filter(e => matches(e, term.toLowerCase()))
    readonly property var calc: mode === "calc" ? Calc.evaluate(term) : ({ ok: false, text: "" })

    // Every word of the query must appear in the name, description or keywords.
    function matches(entry, words) {
        const haystack = [entry.name, entry.genericName, entry.comment, ...(entry.keywords ?? [])]
            .join(" ").toLowerCase();
        return words.split(/\s+/).every(w => haystack.includes(w));
    }

    // Exec= field codes (%f, %U, ...) are placeholders for files and URLs; with
    // nothing to open they are dropped. Terminal=true apps (btop, nvim) run in kitty.
    function launch(entry) {
        const command = entry.command.filter(arg => !/^%[fFuUdDnNickvm]$/.test(arg));
        Quickshell.execDetached({
            command: entry.runInTerminal ? ["kitty", "-e", ...command] : command,
            workingDirectory: entry.workingDirectory || Quickshell.env("HOME"),
        });
        MenuState.close();
    }

    // zsh -c is not interactive: .zshrc (aliases, fastfetch) is not loaded.
    function run(inTerminal) {
        if (root.term === "") return;
        Quickshell.execDetached(inTerminal
            ? ["kitty", "--hold", "zsh", "-c", root.term]
            : ["zsh", "-c", root.term]);
        MenuState.close();
    }

    function activate(shift) {
        if (root.mode === "run") root.run(!shift);
        else if (root.mode === "calc") {
            if (!root.calc.ok) return;
            Quickshell.execDetached(["wl-copy", root.calc.text]);
            MenuState.close();
        } else if (list.currentIndex >= 0 && list.currentIndex < root.results.length) {
            root.launch(root.results[list.currentIndex]);
        }
    }

    onOpened: {
        input.text = "";
        list.currentIndex = 0;
        input.forceActiveFocus();
    }

    ColumnLayout {
        anchors { fill: parent; margins: 14 }
        spacing: 10

        // Search field
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 14
            color: Qt.alpha(Theme.surfaceContainerHigh, 0.7)

            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                spacing: 10

                MaterialIcon {
                    icon: root.mode === "run" ? "terminal" : root.mode === "calc" ? "calculate" : "search"
                    color: Theme.primary
                    font.pixelSize: 22
                }

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
                    Keys.onReturnPressed: event => root.activate(event.modifiers & Qt.ShiftModifier)
                    Keys.onEnterPressed: event => root.activate(event.modifiers & Qt.ShiftModifier)
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onTabPressed: list.incrementCurrentIndex()

                    Label {
                        visible: input.text === ""
                        text: "Search apps    > run    = calculate"
                        color: Theme.surfaceTextMuted
                        font.pixelSize: Theme.fontSize + 1
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // Apps
        ListView {
            id: list
            visible: root.mode === "apps"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.results
            highlightMoveDuration: 0
            keyNavigationWraps: true

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem
                readonly property string iconSource: Quickshell.iconPath(modelData.icon, true)

                width: ListView.view.width
                height: 52
                radius: 12
                color: current ? Qt.alpha(Theme.primary, 0.22) : "transparent"

                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    spacing: 12

                    Item {
                        implicitWidth: 32
                        implicitHeight: 32
                        IconImage {
                            anchors.fill: parent
                            visible: row.iconSource !== ""
                            source: row.iconSource
                            mipmap: true
                        }
                        MaterialIcon {         // no theme icon: generic glyph (as on the bar)
                            anchors.centerIn: parent
                            visible: row.iconSource === ""
                            icon: "apps"
                            font.pixelSize: 26
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label {
                            text: row.modelData.name
                            font.weight: row.current ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Label {
                            visible: text !== ""
                            text: row.modelData.genericName || row.modelData.comment
                            color: Theme.surfaceTextMuted
                            font.pixelSize: Theme.fontSize - 1
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    MaterialIcon {
                        visible: row.modelData.runInTerminal
                        icon: "terminal"
                        color: Theme.surfaceTextMuted
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: list.currentIndex = row.index
                    onClicked: root.launch(row.modelData)
                }
            }

            Label {
                anchors.centerIn: parent
                visible: root.results.length === 0
                text: "No apps match"
                color: Theme.surfaceTextMuted
            }
        }

        // Command / calculator result
        ColumnLayout {
            visible: root.mode !== "apps"
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            Label {
                text: root.mode === "run"
                    ? (root.term === "" ? "Type a command" : root.term)
                    : (root.calc.text === "" ? "Type an expression" : root.calc.ok ? `= ${root.calc.text}` : root.calc.text)
                color: root.mode === "calc" && root.calc.ok ? Theme.primary
                     : root.mode === "calc" && root.calc.text !== "" ? Theme.error
                     : Theme.surfaceText
                font.pixelSize: root.mode === "calc" && root.calc.ok ? 30 : Theme.fontSize + 3
                font.weight: Font.DemiBold
                wrapMode: Text.WrapAnywhere
                Layout.fillWidth: true
                Layout.topMargin: 10
                Layout.leftMargin: 6
            }
            Label {
                visible: root.mode === "calc"
                text: "+ - * / % ^ ( )   sqrt sin cos tan log ln exp abs min max   pi e"
                color: Theme.surfaceTextMuted
                font.pixelSize: Theme.fontSize - 1
                Layout.leftMargin: 6
            }
            Item { Layout.fillHeight: true }
        }

        // Key hints
        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: Theme.surfaceTextMuted
            font.pixelSize: Theme.fontSize - 2
            text: root.mode === "run" ? "Enter: run in kitty   ·   Shift + Enter: run in the background   ·   Esc: close"
                : root.mode === "calc" ? "Enter: copy the result   ·   Esc: close"
                : "↑ ↓: select   ·   Enter: open   ·   Esc: close"
        }
    }
}
