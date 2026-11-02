// Full-screen layer for one menu (launcher, clipboard, power, wallpaper, overview): a light
// dim over the screen and a rounded panel in the middle. A click on the dim or
// Esc in the menu closes it. Keyboard input goes only to the menu while it is open.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    required property string menuName       // MenuState.open value that shows this menu
    default property alias content: panel.data
    property int panelWidth: 560
    property int panelHeight: 480
    property alias panelColor: panel.color
    property real dimOpacity: 0.15          // above ignore_alpha (0.2) Hyprland also blurs the screen behind
    property bool animated: false           // fade + zoom the panel in on open

    signal opened                           // reset the menu and give the focus here

    // Opens on the monitor that has focus.
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: MenuState.open === menuName

    WlrLayershell.layer: WlrLayer.Overlay
    // Blur namespace in hyprland.lua; the default dim (alpha 0.15) is below its
    // ignore_alpha, so only the panel is blurred.
    WlrLayershell.namespace: "quickshell-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: if (visible) {
        opened();
        if (animated) openAnimation.restart();
    }

    ParallelAnimation {
        id: openAnimation
        NumberAnimation { target: dim; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
        NumberAnimation { target: panel; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
        NumberAnimation { target: panel; property: "scale"; from: 0.95; to: 1; duration: 180; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: dim
        anchors.fill: parent
        color: Qt.alpha("#000000", root.dimOpacity)
        MouseArea { anchors.fill: parent; onClicked: MenuState.close() }
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: root.panelWidth
        height: root.panelHeight
        radius: 20
        color: Qt.alpha(Theme.surface, 0.8)
        border.width: 1
        border.color: Qt.alpha(Theme.outlineVariant, 0.6)

        MouseArea { anchors.fill: parent }      // clicks on the panel do not reach the dim
    }
}
