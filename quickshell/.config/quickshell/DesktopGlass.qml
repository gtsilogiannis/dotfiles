// Frosted glass for a depth desktop card: the wallpaper under the card, taken a
// margin wider so the blur has real pixels at its edges. The wallpaper never moves,
// so the blur is drawn once. The card must be a sibling of the backdrop.
import QtQuick
import QtQuick.Effects

Item {
    id: root

    required property Item backdrop             // the wallpaper Image of the desktop layer
    readonly property Item card: parent
    property int radius: Theme.radius * 2
    readonly property int blurMargin: 48        // wallpaper taken around the card for the blur

    anchors.fill: parent

    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: shape
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        MultiEffect {
            x: -root.blurMargin
            y: -root.blurMargin
            width: root.width + 2 * root.blurMargin
            height: root.height + 2 * root.blurMargin
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            saturation: 0.2
            source: ShaderEffectSource {
                sourceItem: root.backdrop
                // The card in wallpaper coordinates, plus the margin
                sourceRect: Qt.rect(root.card.x - root.backdrop.x - root.blurMargin,
                                    root.card.y - root.backdrop.y - root.blurMargin,
                                    root.width + 2 * root.blurMargin,
                                    root.height + 2 * root.blurMargin)
                hideSource: false
            }
        }
    }

    Item {
        id: shape
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle { anchors.fill: parent; radius: root.radius }
    }

    // Tint and edge, as on the bar islands
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Qt.alpha(Theme.surface, 0.35)
        border.width: 1
        border.color: Qt.alpha(Theme.outlineVariant, 0.6)
    }
}
