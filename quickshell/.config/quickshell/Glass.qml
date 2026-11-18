// Glass of one bar island: translucent and blurred by Hyprland in browsing,
// almost opaque in focus.
import QtQuick

Rectangle {
    // Only the alpha animates: Theme already fades the colors themselves.
    property real glass: ModeState.focus ? 0.92 : 0.55
    Behavior on glass { NumberAnimation { duration: Theme.colorFade } }

    implicitHeight: Theme.barHeight
    radius: height / 2
    color: Qt.alpha(Theme.surface, glass)
    border.width: 1
    border.color: Qt.alpha(Theme.outlineVariant, 0.6)
}
