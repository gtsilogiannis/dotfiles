// Glass background of one bar island (a module pill or the workspace strip).
// Translucent in browsing, where Hyprland blurs what lies behind it; almost opaque
// in focus, where the blur is off. The gaps between islands stay fully transparent,
// and ignore_alpha in the layer rule keeps them unblurred.
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
