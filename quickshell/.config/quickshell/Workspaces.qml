// Workspace indicator: one dot per workspace, the focused one stretches into a pill.
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    id: root

    // Always show 1..5, more if a higher workspace exists.
    readonly property int count: Math.max(5, ...Hyprland.workspaces.values.map(w => w.id))

    spacing: 6

    Repeater {
        model: root.count

        Rectangle {
            id: dot

            required property int index
            readonly property int wsId: index + 1
            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
            readonly property bool focused: Hyprland.focusedWorkspace?.id === wsId
            readonly property bool occupied: ws !== null && ws.toplevels.values.length > 0

            implicitWidth: focused ? 26 : 10
            implicitHeight: 10
            radius: height / 2
            color: focused ? Theme.primary
                 : ws?.urgent ? Theme.error
                 : occupied ? Theme.surfaceTextMuted
                 : Theme.outlineVariant

            Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 180 } }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4                 // larger click target than the dot
                cursorShape: Qt.PointingHandCursor
                // The Lua config uses the hl.dsp syntax; legacy configs use "workspace N".
                onClicked: Hyprland.dispatch(Hyprland.usingLua
                    ? `hl.dsp.focus({ workspace = "${dot.wsId}" })`
                    : `workspace ${dot.wsId}`)
            }
        }
    }
}
