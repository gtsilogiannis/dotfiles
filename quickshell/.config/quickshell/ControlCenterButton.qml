// Control center button, a two-slider glyph drawn with shapes to follow the theme.
// Left click: control center. Right click: Do Not Disturb.
import QtQuick

Pill {
    id: root

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) NotificationService.dnd = !NotificationService.dnd;
        else ControlCenterState.toggle();
    }

    // 18 x 18: two tracks, filled up to a round knob; the lower one set lower.
    Item {
        implicitWidth: 18
        implicitHeight: 18

        Rectangle { y: 4; width: 18; height: 2; radius: 1; color: Qt.alpha(Theme.primary, 0.4) }
        Rectangle { y: 4; width: 11; height: 2; radius: 1; color: Theme.primary }
        Rectangle { x: 8; y: 1.5; width: 7; height: 7; radius: 3.5; color: Theme.primary }

        Rectangle { y: 12; width: 18; height: 2; radius: 1; color: Qt.alpha(Theme.primary, 0.4) }
        Rectangle { y: 12; width: 5; height: 2; radius: 1; color: Theme.primary }
        Rectangle { x: 3; y: 9.5; width: 7; height: 7; radius: 3.5; color: Theme.primary }
    }
}
