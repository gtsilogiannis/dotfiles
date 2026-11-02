// Control center on the right edge, below the bar: toggles, volume and
// brightness, media, notification history, and Wi-Fi / Bluetooth views.
// Opens from the bar bell or SUPER + N; closes on Esc or a click outside.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire

PanelWindow {
    id: root

    // Opens on the monitor that has focus.
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors { top: true; right: true; bottom: true }
    margins { top: Theme.gap * 2 + Theme.barHeight; right: Theme.gap; bottom: Theme.gap }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 400
    color: "transparent"
    visible: ControlCenterState.open

    WlrLayershell.namespace: "quickshell-controlcenter"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand     // for Esc

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var adapter: Bluetooth.defaultAdapter

    PwObjectTracker { objects: [root.sink] }

    onVisibleChanged: {
        if (!visible) { ControlCenterState.page = "main"; return; }
        Brightness.refresh();           // the brightness keys may have changed it
        panel.forceActiveFocus();       // Esc works without clicking first
    }

    // Click outside the panel closes it.
    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onCleared: ControlCenterState.close()
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: 20
        color: Qt.alpha(Theme.surface, 0.75)
        border.width: 1
        border.color: Qt.alpha(Theme.outlineVariant, 0.6)

        focus: true
        // Esc steps back from the Wi-Fi / Bluetooth view first, then closes.
        Keys.onEscapePressed: {
            if (ControlCenterState.page !== "main") ControlCenterState.page = "main";
            else ControlCenterState.close();
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            GridLayout {
                columns: 4
                columnSpacing: 8
                Layout.fillWidth: true

                // Same as Bluetooth: off -> a tap turns it on; on -> a tap opens the network list.
                QuickToggle {
                    icon: "wifi"
                    label: "Wi-Fi"
                    active: Networking.wifiEnabled
                    onClicked: {
                        if (!Networking.wifiEnabled) Networking.wifiEnabled = true;
                        else ControlCenterState.page = "wifi";
                    }
                }
                // Off: a tap turns it on. On: a tap opens the device view,
                // which has the button to turn it off (like iOS / Windows).
                QuickToggle {
                    icon: "bluetooth"
                    label: "Bluetooth"
                    available: root.adapter !== null
                    active: root.adapter?.enabled ?? false
                    onClicked: {
                        if (!root.adapter.enabled) root.adapter.enabled = true;
                        else ControlCenterState.page = "bluetooth";
                    }
                }
                QuickToggle {
                    icon: "do_not_disturb_on"
                    label: "DND"
                    active: NotificationService.dnd
                    onClicked: NotificationService.dnd = !NotificationService.dnd
                }
                QuickToggle {
                    icon: "nightlight"
                    label: "Night"
                    active: NightLight.active
                    onClicked: NightLight.toggle()
                }
            }

            WifiPage {
                visible: ControlCenterState.page === "wifi"
                onBack: ControlCenterState.page = "main"
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            BluetoothPage {
                visible: ControlCenterState.page === "bluetooth"
                adapter: root.adapter
                onBack: ControlCenterState.page = "main"
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            Card {
                visible: ControlCenterState.page === "main"
                Layout.fillWidth: true

                SliderRow {
                    icon: (root.sink?.audio?.muted ?? false) ? "volume_off" : "volume_up"
                    available: !!root.sink?.audio
                    value: root.sink?.audio?.volume ?? 0
                    onMoved: v => root.sink.audio.volume = v       // 0..1, same 100% cap as the bar
                    Layout.fillWidth: true
                }
                SliderRow {
                    icon: "brightness_6"
                    available: Brightness.available
                    value: Brightness.value
                    onMoved: v => Brightness.set(v)
                    Layout.fillWidth: true
                }
            }

            MediaCard {
                visible: ControlCenterState.page === "main" && player !== null
                Layout.fillWidth: true
            }

            RowLayout {
                visible: ControlCenterState.page === "main"
                Layout.fillWidth: true
                Layout.topMargin: 4

                Label {
                    text: NotificationService.history.length > 0
                        ? `Notifications (${NotificationService.history.length})`
                        : "No notifications"
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                Label {
                    visible: NotificationService.history.length > 0
                    text: "Clear all"
                    color: clearArea.containsMouse ? Theme.error : Theme.primary
                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationService.clearAll()
                    }
                }
            }

            ListView {
                visible: ControlCenterState.page === "main"
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                // Newest first.
                model: [...NotificationService.history].reverse()

                delegate: NotificationCard {
                    required property var modelData
                    notification: modelData
                    width: ListView.view.width
                }
            }
        }
    }
}
