// Top bar: workspaces, media and clock, system modules. The bar is transparent;
// every module is its own glass island.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar

    anchors { top: true; left: true; right: true }
    // Same distance from the screen edges as the windows (gaps_out).
    margins { top: Theme.gap; left: Theme.gap; right: Theme.gap }
    implicitHeight: Theme.barHeight
    color: "transparent"

    // Hyprland matches this name in hl.layer_rule to blur behind the islands.
    WlrLayershell.namespace: "quickshell-bar"

    // Caffeine: the bars are always mapped, so their inhibitors hold off hypridle.
    IdleInhibitor {
        window: bar
        enabled: Caffeine.active
    }

    Workspaces {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    }

    // Over an empty depth desktop, which draws its own clock and media card
    RowLayout {
        id: center
        readonly property bool yielded: DepthState.shownOn(bar.screen)

        anchors.centerIn: parent
        spacing: Theme.gap
        opacity: yielded ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Media {}
        Clock {}
    }

    StatusModules {
        window: bar
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
    }
}
