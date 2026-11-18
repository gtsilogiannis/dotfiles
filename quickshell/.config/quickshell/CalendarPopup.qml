// Calendar popup under the bar clock; Esc or a click outside closes it.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors.top: true                       // centered horizontally, like the clock
    margins.top: Theme.gap * 2 + Theme.barHeight
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 320
    implicitHeight: calendar.implicitHeight
    color: "transparent"
    visible: CalendarState.open

    WlrLayershell.namespace: "quickshell-calendar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onVisibleChanged: {
        if (!visible) return;
        calendar.monthOffset = 0;           // always opens on the current month
        calendar.forceActiveFocus();
    }

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onCleared: CalendarState.close()
    }

    CalendarCard {
        id: calendar
        width: parent.width
        live: root.visible
        color: Qt.alpha(Theme.surface, 0.8)
        border.width: 1
        border.color: Qt.alpha(Theme.outlineVariant, 0.6)
        focus: true
        Keys.onEscapePressed: CalendarState.close()
    }
}
