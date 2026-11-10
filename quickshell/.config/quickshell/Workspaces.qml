// Workspaces 1..5 (more if a higher one exists) on one glass island. Each chip shows
// the icons of its windows; an empty workspace shows its number. The focused chip is
// tinted, the others are bare until hovered.
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Widgets

Glass {
    id: root

    readonly property int count: Math.max(5, ...Hyprland.workspaces.values.map(w => w.id))

    implicitWidth: chips.implicitWidth + 8      // 4 px around the chips, as above and below

    RowLayout {
        id: chips
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.count

            Rectangle {
                id: chip

                required property int index
                readonly property int wsId: index + 1
                readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                readonly property bool focused: Hyprland.focusedWorkspace?.id === wsId
                // One icon per app: two kitty windows show one kitty icon.
                readonly property var appIds: {
                    const ids = (ws?.toplevels.values ?? []).map(t => Apps.idOf(t)).filter(id => id !== "");
                    return [...new Set(ids)].slice(0, 4);
                }

                Layout.preferredWidth: Math.max(Theme.pillHeight, icons.implicitWidth + 14)
                Layout.preferredHeight: Theme.pillHeight
                radius: height / 2
                color: focused ? Qt.alpha(Theme.primary, 0.25)
                     : mouse.containsMouse ? Qt.alpha(Theme.surfaceContainerHigh, 0.9)
                     : "transparent"
                border.width: focused ? 1 : 0
                border.color: Theme.primary
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on Layout.preferredWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Row {
                    id: icons
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: chip.appIds

                        Item {
                            id: app
                            required property string modelData
                            readonly property string iconSource: Apps.icon(modelData)
                            implicitWidth: 16
                            implicitHeight: 16
                            opacity: chip.focused ? 1 : 0.7

                            IconImage {
                                anchors.fill: parent
                                visible: app.iconSource !== ""
                                source: app.iconSource
                                mipmap: true
                            }
                            // No theme icon for this app: a generic glyph keeps the window visible.
                            MaterialIcon {
                                anchors.centerIn: parent
                                visible: app.iconSource === ""
                                icon: "apps"
                                font.pixelSize: 16
                            }
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: chip.appIds.length === 0
                    text: chip.wsId
                    font.family: Theme.monoFamily
                    color: chip.focused ? Theme.primary : Theme.surfaceTextMuted
                    font.weight: chip.focused ? Font.Bold : Font.Normal
                }

                Rectangle {     // urgent window on this workspace
                    visible: chip.ws?.urgent ?? false
                    width: 6; height: 6; radius: 3
                    anchors { top: parent.top; right: parent.right; topMargin: 2; rightMargin: 4 }
                    color: Theme.error
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    // The Lua config uses the hl.dsp syntax; legacy configs use "workspace N".
                    onClicked: Hyprland.dispatch(Hyprland.usingLua
                        ? `hl.dsp.focus({ workspace = "${chip.wsId}" })`
                        : `workspace ${chip.wsId}`)
                }
            }
        }
    }
}
