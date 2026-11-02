// Workspace overview (SUPER + Tab): the workspaces that have windows (and the focused
// one) in rows of up to 5, plus one empty workspace to drag windows to. Each tile shows
// the wallpaper and a frozen preview of every window at its real place.
//   click window      focus it (switches workspace) and close the overview
//   middle-click      close the window
//   drag window       move it to the tile it is dropped on, without following it
//   click empty tile  go to that workspace
//   typing            dims the windows that do not match title / app; Enter focuses the first match
//   arrows, 1-0       select a shown workspace; Enter goes there; Esc clears the search, then closes
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

MenuWindow {
    id: root

    menuName: "overview"
    dimOpacity: 0.45                        // darker than the other menus: the tiles are the focus
    animated: true

    // Workspaces 1-10 with windows, plus the focused one even when empty.
    readonly property var usedIds: {
        const ids = Hyprland.workspaces.values
            .filter(w => w.id >= 1 && w.id <= 10 && w.toplevels.values.length > 0)
            .map(w => w.id);
        const focused = Hyprland.focusedWorkspace?.id ?? 0;
        if (focused >= 1 && focused <= 10 && !ids.includes(focused)) ids.push(focused);
        return ids.sort((a, b) => a - b);
    }
    // First free workspace, shown last as a drop target for moving windows (0 when all 10 are used).
    readonly property int freeId: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].find(id => !usedIds.includes(id)) ?? 0
    readonly property var shownIds: freeId > 0 ? [...usedIds, freeId] : usedIds

    readonly property int maxColumns: 5
    readonly property int columns: Math.max(1, Math.min(maxColumns, shownIds.length))
    readonly property int rows: Math.max(1, Math.ceil(shownIds.length / maxColumns))
    readonly property int tileSpacing: 12

    // Tile size follows the aspect ratio of the monitor the overview opens on.
    readonly property var monitor: Hyprland.focusedMonitor
    readonly property real monitorWidth: monitor ? monitor.width / monitor.scale : 1920
    readonly property real monitorHeight: monitor ? monitor.height / monitor.scale : 1080
    // Sized for 5 per row, so a few workspaces do not turn into huge tiles.
    readonly property real tileWidth: Math.min(330, (root.screen.width * 0.92 - 28 - (maxColumns - 1) * tileSpacing) / maxColumns)
    readonly property real tileHeight: tileWidth * monitorHeight / monitorWidth

    panelWidth: columns * tileWidth + (columns - 1) * tileSpacing + 28
    panelHeight: rows * tileHeight + (rows - 1) * tileSpacing + 28 + 48 + 10 + 20 + 10

    property int selected: 0                // index in shownIds chosen with the keyboard
    property var dragged: null              // HyprlandToplevel being dragged
    property int dropIndex: -1              // tile under the cursor while dragging
    property string wallpaper: ""           // reloaded on every open (set-wallpaper.sh rewrites the file)
    readonly property Item dragLayer: ghost.parent   // the panel: OverviewWindow maps the cursor into it

    readonly property string query: search.text.trim().toLowerCase()
    // Windows on workspaces 1-10 that match every word of the query, by workspace.
    readonly property var matches: query === "" ? []
        : Hyprland.toplevels.values
            .filter(t => (t.workspace?.id ?? 0) >= 1 && t.workspace.id <= 10 && matchesQuery(t))
            .sort((a, b) => a.workspace.id - b.workspace.id)

    function matchesQuery(t) {
        const id = Apps.idOf(t);
        const haystack = [t.title, id, Apps.name(id)].join(" ").toLowerCase();
        return root.query.split(/\s+/).every(w => haystack.includes(w));
    }

    // Hyprland selectors take the address with its 0x prefix; Quickshell reports it without.
    function selector(t) { return "address:0x" + t.address; }

    // The Lua config uses the hl.dsp syntax; legacy configs use the old dispatcher names.
    function focusWindow(t) {
        if (!t || t.address === "") return;
        Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.focus({ window = "${selector(t)}" })`
            : `focuswindow ${selector(t)}`);
        MenuState.close();
    }

    function moveWindow(t, wsId) {
        if (!t || t.address === "" || t.workspace?.id === wsId) return;
        Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.window.move({ workspace = ${wsId}, follow = false, window = "${selector(t)}" })`
            : `movetoworkspacesilent ${wsId},${selector(t)}`);
        refresh.restart();
    }

    function closeWindow(t) {
        if (!t || t.address === "") return;
        Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.window.close({ window = "${selector(t)}" })`
            : `closewindow ${selector(t)}`);
        refresh.restart();
    }

    function goTo(wsId) {
        Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.focus({ workspace = "${wsId}" })`
            : `workspace ${wsId}`);
        MenuState.close();
    }

    // Left / right walk the tiles in order; up / down jump a row when there is one.
    function moveSelection(dx, dy) {
        const n = root.shownIds.length;
        if (n === 0) return;
        if (dx !== 0) root.selected = (root.selected + dx + n) % n;
        else {
            const next = root.selected + dy * root.columns;
            if (next >= 0 && next < n) root.selected = next;
        }
    }

    // Window positions come from the IPC objects, which update only when fetched.
    onOpened: {
        Hyprland.refreshMonitors();
        Hyprland.refreshToplevels();
        root.wallpaper = "";
        root.wallpaper = "file://" + Quickshell.env("HOME") + "/.cache/current_wallpaper.png";
        search.text = "";
        root.dragged = null;
        root.dropIndex = -1;
        root.selected = Math.max(0, root.shownIds.indexOf(Hyprland.focusedWorkspace?.id ?? 0));
        search.forceActiveFocus();
        report.restart();
    }

    // After a move or close Hyprland retiles the workspace; fetch the new geometry.
    Timer {
        id: refresh
        interval: 150
        onTriggered: Hyprland.refreshToplevels()
    }

    // One line per open in the log: how many windows have geometry to be drawn.
    Timer {
        id: report
        interval: 500
        onTriggered: {
            const all = Hyprland.toplevels.values.filter(t => (t.workspace?.id ?? 0) >= 1 && t.workspace.id <= 10);
            const placed = all.filter(t => t.lastIpcObject?.at?.length === 2);
            let drawn = 0;
            for (let i = 0; i < tiles.count; i++) drawn += tiles.itemAt(i)?.windowCount ?? 0;
            console.info(`Overview: ${all.length} windows on workspaces 1-10, ${placed.length} with geometry, ${drawn} in the tiles`);
        }
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

                MaterialIcon { icon: "search"; color: Theme.primary; font.pixelSize: 22 }

                TextInput {
                    id: search
                    Layout.fillWidth: true
                    color: Theme.surfaceText
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.primaryText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 3
                    clip: true

                    // Runs before the field handles the key, so arrows and digits
                    // can select workspaces instead of moving the text cursor.
                    Keys.onPressed: event => {
                        const k = event.key;
                        if (k === Qt.Key_Escape) {
                            if (search.text !== "") search.text = "";
                            else MenuState.close();
                        } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                            if (root.query !== "") root.focusWindow(root.matches[0] ?? null);
                            else if (root.selected < root.shownIds.length) root.goTo(root.shownIds[root.selected]);
                        } else if (k === Qt.Key_Left) root.moveSelection(-1, 0);
                        else if (k === Qt.Key_Right) root.moveSelection(1, 0);
                        else if (k === Qt.Key_Up) root.moveSelection(0, -1);
                        else if (k === Qt.Key_Down) root.moveSelection(0, 1);
                        else if (search.text === "" && k >= Qt.Key_0 && k <= Qt.Key_9) {
                            const i = root.shownIds.indexOf(k === Qt.Key_0 ? 10 : k - Qt.Key_0);
                            if (i >= 0) root.selected = i;              // digits of hidden workspaces do nothing
                        }
                        else return;
                        event.accepted = true;
                    }

                    Label {
                        visible: search.text === ""
                        text: "Search windows"
                        color: Theme.surfaceTextMuted
                        font.pixelSize: Theme.fontSize + 1
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Label {
                    visible: root.query !== ""
                    text: root.matches.length === 1 ? "1 window" : `${root.matches.length} windows`
                    color: Theme.surfaceTextMuted
                }
            }
        }

        // Workspaces
        Grid {
            id: grid
            columns: root.columns
            spacing: root.tileSpacing

            Repeater {
                id: tiles
                model: root.shownIds

                Rectangle {
                    id: wsTile

                    required property int index
                    required property int modelData
                    readonly property int wsId: modelData
                    readonly property bool isFree: wsId === root.freeId
                    readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                    readonly property var mon: ws?.monitor ?? root.monitor
                    // Layout pixels -> tile pixels.
                    readonly property real scaleFactor: mon ? width / (mon.width / mon.scale) : width / root.monitorWidth
                    readonly property bool active: Hyprland.focusedWorkspace?.id === wsId
                    readonly property int windowCount: windowRepeater.count
                    readonly property bool highlighted: root.dragged ? root.dropIndex === index : root.selected === index

                    width: root.tileWidth
                    height: root.tileHeight
                    radius: Theme.radius
                    color: Qt.alpha(Theme.surfaceContainerHigh, 0.7)
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.visible ? root.wallpaper : ""
                        sourceSize.width: 480              // decode small: 4K wallpapers stay cheap
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        opacity: wsTile.isFree ? 0.3 : 0.85      // the free drop target stays in the background
                    }

                    // Click on the empty part of the tile: go to the workspace.
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: if (!root.dragged) root.selected = wsTile.index
                        onClicked: root.goTo(wsTile.wsId)
                    }

                    Repeater {
                        id: windowRepeater
                        model: wsTile.ws?.toplevels ?? null

                        OverviewWindow {
                            required property var modelData
                            toplevel: modelData
                            tile: wsTile
                            overview: root
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: wsTile.isFree
                        icon: "add"
                        color: Theme.surfaceTextMuted
                        font.pixelSize: 32
                    }

                    // Workspace number
                    Rectangle {
                        anchors { left: parent.left; bottom: parent.bottom; margins: 8 }
                        width: Math.max(24, number.implicitWidth + 12)
                        height: 24
                        radius: 12
                        color: wsTile.active ? Theme.primary : Qt.alpha(Theme.surface, 0.8)
                        z: 5

                        Label {
                            id: number
                            anchors.centerIn: parent
                            text: wsTile.wsId
                            color: wsTile.active ? Theme.primaryText : Theme.surfaceText
                            font.weight: Font.DemiBold
                        }
                    }

                    // Selection / drop target frame, above the windows.
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.width: wsTile.highlighted ? 3 : wsTile.active ? 1 : 0
                        border.color: Theme.primary
                        z: 6
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: Theme.surfaceTextMuted
            font.pixelSize: Theme.fontSize - 2
            text: "Click: focus   ·   Middle-click: close   ·   Drag: move (+ = empty workspace)   ·   ← ↑ → ↓ / 1–0: workspace   ·   Enter: go   ·   Esc: close"
        }
    }

    // While a window is dragged a small card with its icon follows the cursor.
    Rectangle {
        id: ghost
        visible: root.dragged !== null
        width: 56
        height: 56
        radius: 14
        z: 20
        color: Qt.alpha(Theme.surfaceContainerHigh, 0.95)
        border.width: 2
        border.color: Theme.primary

        readonly property string iconSource: Apps.icon(Apps.idOf(root.dragged))

        IconImage {
            anchors.centerIn: parent
            implicitSize: 34
            visible: ghost.iconSource !== ""
            source: ghost.iconSource
            mipmap: true
        }
        MaterialIcon {
            anchors.centerIn: parent
            visible: ghost.iconSource === ""
            icon: "apps"
            font.pixelSize: 30
        }
    }

    // Called by OverviewWindow with the cursor in panel coordinates.
    function dragMove(t, p) {
        root.dragged = t;
        ghost.x = p.x - ghost.width / 2;
        ghost.y = p.y - ghost.height / 2;
        root.dropIndex = -1;
        for (let i = 0; i < tiles.count; i++) {
            const item = tiles.itemAt(i);
            if (item.contains(root.dragLayer.mapToItem(item, p.x, p.y))) { root.dropIndex = i; break; }
        }
    }

    function dragEnd() {
        if (root.dragged && root.dropIndex >= 0) root.moveWindow(root.dragged, root.shownIds[root.dropIndex]);
        root.dragged = null;
        root.dropIndex = -1;
    }
}
