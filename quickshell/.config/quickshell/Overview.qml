// Workspace overview (SUPER + Tab): the workspaces that have windows (and the focused
// one) in rows of up to 5, straight on the blurred screen, plus a narrow slot for the
// first empty workspace to drag windows to. Each tile shows the wallpaper and a frozen
// preview of every window at its real place; below it, the number and the apps.
//   click window      focus it (switches workspace) and close the overview
//   middle-click      close the window
//   drag window       move it to the tile it is dropped on, without following it
//   click empty tile  go to that workspace; click between the tiles: close
//   typing            shows the search, dims the windows that do not match title / app;
//                     Enter focuses the first match
//   arrows, 1-0       select a shown workspace; Enter goes there; Esc clears the search, then closes
//   hold ?            show the shortcuts
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

MenuWindow {
    id: root

    menuName: "overview"
    dimOpacity: 0.45                        // darker than the other menus: the tiles are the focus
    animated: true
    framed: false

    // The panel covers the screen; the content is centred in it.
    panelWidth: root.screen?.width ?? 1920
    panelHeight: root.screen?.height ?? 1080

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
    readonly property int rows: Math.max(1, Math.ceil(shownIds.length / maxColumns))
    readonly property var rowIds: Array.from({ length: rows }, (_, r) => shownIds.slice(r * maxColumns, (r + 1) * maxColumns))

    readonly property int columnSpacing: 24
    readonly property int rowSpacing: 18
    readonly property int labelHeight: 22
    readonly property int searchHeight: 44
    readonly property int helpHeight: 20
    readonly property real freeFraction: 0.3        // width of the free slot, relative to a tile

    // Tile size follows the aspect ratio of the monitor the overview opens on.
    readonly property var monitor: Hyprland.focusedMonitor
    readonly property real monitorWidth: monitor ? monitor.width / monitor.scale : 1920
    readonly property real monitorHeight: monitor ? monitor.height / monitor.scale : 1080
    // As large as the screen allows: at most 30% of its width, the first (widest) row
    // within 90% of the width, all rows within 85% of the height.
    readonly property real tileWidth: {
        const screenW = root.screen?.width ?? 1920;
        const screenH = root.screen?.height ?? 1080;
        const first = rowIds[0] ?? [];
        const units = first.length - (first.includes(freeId) ? 1 - freeFraction : 0);
        const byWidth = (screenW * 0.9 - (first.length - 1) * columnSpacing) / Math.max(1, units);
        const availH = screenH * 0.85 - searchHeight - helpHeight - 2 * 20;
        const byHeight = ((availH - (rows - 1) * rowSpacing) / rows - labelHeight - 6) * monitorWidth / monitorHeight;
        return Math.floor(Math.max(120, Math.min(screenW * 0.3, byWidth, byHeight)));   // whole pixels, as the windows
    }
    readonly property real tileHeight: Math.round(tileWidth * monitorHeight / monitorWidth)

    property int selected: 0                // index in shownIds chosen with the keyboard
    property var dragged: null              // HyprlandToplevel being dragged
    property int dropIndex: -1              // tile under the cursor while dragging
    property string wallpaper: ""           // reloaded on every open (set-wallpaper.sh rewrites the file)
    property bool showHelp: false           // while ? is held
    property var tileItems: []              // tile delegates by index in shownIds, for drag hit tests
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

    // Left / right walk the tiles in order; up / down jump a row (to the last tile
    // when the next row is shorter).
    function moveSelection(dx, dy) {
        const n = root.shownIds.length;
        if (n === 0) return;
        if (dx !== 0) root.selected = (root.selected + dx + n) % n;
        else {
            const next = root.selected + dy * root.maxColumns;
            if (next >= 0 && next < n) root.selected = next;
            else if (dy > 0 && Math.floor(root.selected / root.maxColumns) < root.rows - 1) root.selected = n - 1;
        }
    }

    // Distinct app names of the windows on a workspace, for the label under its tile.
    function appNames(ws) {
        const names = (ws?.toplevels.values ?? []).map(t => Apps.name(Apps.idOf(t))).filter(n => n !== "");
        return [...new Set(names)].join(", ");
    }

    // Window positions come from the IPC objects, which update only when fetched.
    onOpened: {
        Hyprland.refreshMonitors();
        Hyprland.refreshToplevels();
        root.wallpaper = "";
        root.wallpaper = "file://" + Quickshell.env("HOME") + "/.cache/current_wallpaper.png";
        search.text = "";
        root.showHelp = false;
        root.dragged = null;
        root.dropIndex = -1;
        root.selected = Math.max(0, root.shownIds.indexOf(Hyprland.focusedWorkspace?.id ?? 0));
        search.forceActiveFocus();
    }

    // After a move or close Hyprland retiles the workspace; fetch the new geometry.
    Timer {
        id: refresh
        interval: 150
        onTriggered: Hyprland.refreshToplevels()
    }

    Column {
        anchors.centerIn: parent
        spacing: 20

        // Search: keeps the keyboard focus, visible only once something is typed.
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(560, (root.screen?.width ?? 1920) * 0.4)
            height: root.searchHeight

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Qt.alpha(Theme.surfaceContainerHigh, 0.85)
                border.width: 1
                border.color: Qt.alpha(Theme.outlineVariant, 0.6)
                opacity: search.text !== "" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }

                Row {
                    anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                    spacing: 10

                    MaterialIcon {
                        id: searchIcon
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "search"
                        color: Theme.primary
                        font.pixelSize: 20
                    }

                    TextInput {
                        id: search
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - searchIcon.width - count.width - 2 * parent.spacing
                        color: Theme.surfaceText
                        selectionColor: Theme.primary
                        selectedTextColor: Theme.primaryText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 2
                        clip: true

                        // Runs before the field handles the key, so arrows and digits
                        // can select workspaces instead of moving the text cursor.
                        Keys.onPressed: event => {
                            const k = event.key;
                            if (k === Qt.Key_Question) root.showHelp = true;
                            else if (k === Qt.Key_Escape) {
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
                        // Key repeat sends release / press pairs: only the real release hides the help.
                        Keys.onReleased: event => {
                            if (event.key !== Qt.Key_Question) return;
                            if (!event.isAutoRepeat) root.showHelp = false;
                            event.accepted = true;
                        }
                    }

                    Label {
                        id: count
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.matches.length === 1 ? "1 window" : `${root.matches.length} windows`
                        color: Theme.surfaceTextMuted
                    }
                }
            }
        }

        // Workspaces, one Row per line so a shorter last line stays centred.
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.rowSpacing

            Repeater {
                model: root.rowIds

                Row {
                    id: tileRow

                    required property int index
                    required property var modelData
                    readonly property int rowIndex: index

                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.columnSpacing

                    Repeater {
                        model: tileRow.modelData

                        Item {
                            id: wsTile

                            required property int index
                            required property int modelData
                            readonly property int globalIndex: tileRow.rowIndex * root.maxColumns + index
                            readonly property int wsId: modelData
                            readonly property bool isFree: wsId === root.freeId
                            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                            readonly property var mon: ws?.monitor ?? root.monitor
                            // Layout pixels -> tile pixels.
                            readonly property real scaleFactor: mon ? width / (mon.width / mon.scale) : width / root.monitorWidth
                            readonly property bool active: Hyprland.focusedWorkspace?.id === wsId
                            readonly property int windowCount: windowRepeater.count
                            readonly property bool highlighted: root.dragged ? root.dropIndex === globalIndex : root.selected === globalIndex

                            width: isFree ? Math.max(64, root.tileWidth * root.freeFraction) : root.tileWidth
                            height: root.tileHeight + 6 + root.labelHeight

                            Component.onCompleted: root.tileItems[globalIndex] = wsTile
                            Component.onDestruction: if (root.tileItems[globalIndex] === wsTile) root.tileItems[globalIndex] = null

                            Rectangle {
                                id: surface
                                width: parent.width
                                height: root.tileHeight
                                radius: Theme.radius
                                color: wsTile.isFree
                                    ? Qt.alpha(Theme.primary, wsTile.highlighted ? 0.18 : 0.04)
                                    : Qt.alpha(Theme.surfaceContainerHigh, 0.7)
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    visible: !wsTile.isFree
                                    source: root.visible && !wsTile.isFree ? root.wallpaper : ""
                                    sourceSize.width: 640          // decode small: 4K wallpapers stay cheap
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                    opacity: 0.85
                                }

                                // Click on the empty part of the tile: go to the workspace.
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: if (!root.dragged) root.selected = wsTile.globalIndex
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

                                // Free slot: dashed outline and a plus, no wallpaper.
                                Shape {
                                    anchors.fill: parent
                                    visible: wsTile.isFree
                                    preferredRendererType: Shape.CurveRenderer

                                    ShapePath {
                                        strokeColor: wsTile.highlighted ? Theme.primary : Qt.alpha(Theme.surfaceTextMuted, 0.6)
                                        strokeWidth: 1.5
                                        strokeStyle: ShapePath.DashLine
                                        dashPattern: [4, 4]
                                        fillColor: "transparent"

                                        PathRectangle {
                                            x: 1
                                            y: 1
                                            width: surface.width - 2
                                            height: surface.height - 2
                                            radius: Theme.radius
                                        }
                                    }
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    visible: wsTile.isFree
                                    icon: "add"
                                    color: wsTile.highlighted ? Theme.primary : Theme.surfaceTextMuted
                                    font.pixelSize: 28
                                }

                                // Keyboard selection / drop target frame, above the windows.
                                Rectangle {
                                    anchors.fill: parent
                                    visible: !wsTile.isFree
                                    radius: parent.radius
                                    color: "transparent"
                                    border.width: wsTile.highlighted ? 2 : 0
                                    border.color: Theme.primary
                                    z: 6
                                }
                            }

                            // Label: number (primary on the focused workspace) and the apps.
                            Row {
                                visible: !wsTile.isFree
                                anchors { top: surface.bottom; topMargin: 6; left: parent.left; right: parent.right; leftMargin: 4 }
                                height: root.labelHeight
                                spacing: 8

                                Label {
                                    id: number
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: wsTile.wsId
                                    color: wsTile.active ? Theme.primary : Theme.surfaceText
                                    font.weight: wsTile.active ? Font.Bold : Font.DemiBold
                                    font.pixelSize: Theme.fontSize + 1
                                }
                                Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - number.width - parent.spacing - 4
                                    text: root.appNames(wsTile.ws)
                                    color: Theme.surfaceTextMuted
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }

        // Shortcuts while ? is held; otherwise a faint reminder.
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            height: root.helpHeight
            color: Theme.surfaceTextMuted
            opacity: root.showHelp ? 0.95 : 0.4
            font.pixelSize: Theme.fontSize - 2
            text: root.showHelp
                ? "Click: focus   ·   Middle-click: close   ·   Drag: move (+ = empty workspace)   ·   ← ↑ → ↓ / 1–0: workspace   ·   Enter: go   ·   type: search   ·   Esc: close"
                : "Hold ? for shortcuts"
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
        for (let i = 0; i < root.shownIds.length; i++) {
            const item = root.tileItems[i];
            if (item && item.contains(root.dragLayer.mapToItem(item, p.x, p.y))) { root.dropIndex = i; break; }
        }
    }

    function dragEnd() {
        if (root.dragged && root.dropIndex >= 0) root.moveWindow(root.dragged, root.shownIds[root.dropIndex]);
        root.dragged = null;
        root.dropIndex = -1;
    }
}
