// Power menu (ALT + F4 and the power button on the bar). Every action runs
// immediately. Keys: ← → and Enter, or the underlined letter.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

MenuWindow {
    id: root

    menuName: "power"
    panelWidth: actions.length * 112 + 28
    panelHeight: 170

    property int selected: 0

    readonly property var actions: [
        { key: "l", icon: "lock",               label: "Lock",     accent: Theme.primary },
        { key: "s", icon: "bedtime",            label: "Suspend",  accent: Theme.primary },
        { key: "o", icon: "logout",             label: "Logout",   accent: Theme.tertiary },
        { key: "r", icon: "restart_alt",        label: "Reboot",   accent: Theme.tertiary },
        { key: "p", icon: "power_settings_new", label: "Shutdown", accent: Theme.error },
    ]

    function run(index) {
        const label = root.actions[index].label;
        MenuState.close();          // close first, so the lock screen is not covered
        if (label === "Lock") Quickshell.execDetached(["hyprlock"]);
        else if (label === "Suspend") Quickshell.execDetached(["systemctl", "suspend"]);
        // The Lua config uses the hl.dsp syntax (same as SUPER + M); legacy configs use "exit".
        else if (label === "Logout") Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.exit()" : "exit");
        else if (label === "Reboot") Quickshell.execDetached(["systemctl", "reboot"]);
        else if (label === "Shutdown") Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    onOpened: {
        root.selected = 0;
        keys.forceActiveFocus();
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: MenuState.close()
        Keys.onLeftPressed: root.selected = (root.selected + root.actions.length - 1) % root.actions.length
        Keys.onRightPressed: root.selected = (root.selected + 1) % root.actions.length
        Keys.onTabPressed: root.selected = (root.selected + 1) % root.actions.length
        Keys.onReturnPressed: root.run(root.selected)
        Keys.onEnterPressed: root.run(root.selected)
        Keys.onPressed: event => {
            const i = root.actions.findIndex(a => a.key === event.text.toLowerCase());
            if (i >= 0) { root.run(i); event.accepted = true; }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: root.actions

                Rectangle {
                    id: button
                    required property var modelData
                    required property int index
                    readonly property bool current: root.selected === index

                    implicitWidth: 104
                    implicitHeight: 128
                    radius: 18
                    color: current ? Qt.alpha(modelData.accent, 0.25) : Qt.alpha(Theme.surfaceContainerHigh, 0.6)
                    border.width: current ? 1 : 0
                    border.color: modelData.accent
                    Behavior on color { ColorAnimation { duration: 120 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10

                        MaterialIcon {
                            icon: button.modelData.icon
                            filled: button.current
                            color: button.modelData.accent
                            font.pixelSize: 40
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Label {
                            // Underline the shortcut letter.
                            textFormat: Text.StyledText
                            text: {
                                const l = button.modelData.label;
                                const i = l.toLowerCase().indexOf(button.modelData.key);
                                return `${l.slice(0, i)}<u>${l[i]}</u>${l.slice(i + 1)}`;
                            }
                            color: button.current ? Theme.surfaceText : Theme.surfaceTextMuted
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selected = button.index
                        onClicked: root.run(button.index)
                    }
                }
            }
        }
    }
}
