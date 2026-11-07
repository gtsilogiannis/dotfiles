// Short on-screen hint in the middle of the focused monitor when the desktop
// mode or the opaque-windows switch changes. Clicks pass through it.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    property string icon
    property string text

    function show(icon, text) {
        root.icon = icon;
        root.text = text;
        root.visible = true;
        box.opacity = 1;
        hideTimer.restart();
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    // No anchors: the compositor centers the surface on the screen.
    implicitWidth: box.implicitWidth
    implicitHeight: box.implicitHeight
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: false
    mask: Region {}                         // empty input region: clicks go to the windows below

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Connections {
        target: ModeState
        function onModeSwitched() {
            if (ModeState.focus) root.show("center_focus_strong", "Focus");
            else root.show("explore", "Browsing");
        }
        function onOpaqueSwitched() {
            if (ModeState.opaque) root.show("opacity", "Opaque windows");
            else root.show("blur_on", "Glass windows");
        }
    }

    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: box.opacity = 0
    }

    Rectangle {
        id: box
        anchors.fill: parent
        implicitWidth: content.implicitWidth + 48
        implicitHeight: content.implicitHeight + 32
        radius: 20
        color: Qt.alpha(Theme.surface, 0.8)
        border.width: 1
        border.color: Qt.alpha(Theme.outlineVariant, 0.6)
        opacity: 0
        scale: 0.95 + 0.05 * opacity
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        onOpacityChanged: if (opacity === 0) root.visible = false

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: 12

            MaterialIcon {
                icon: root.icon
                filled: true
                color: Theme.primary
                font.pixelSize: 28
            }
            Label {
                text: root.text
                font.pixelSize: Theme.fontSize + 6
                font.weight: Font.DemiBold
            }
        }
    }
}
