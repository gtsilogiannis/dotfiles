// Icon and app name of the focused window ("Firefox", not the page title).
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Widgets

Pill {
    id: root

    readonly property string appId: ToplevelManager.activeToplevel?.appId ?? ""

    interactive: false
    visible: appId !== ""

    IconImage { implicitSize: 16; source: Apps.icon(root.appId); mipmap: true }
    Label { text: Apps.name(root.appId); elide: Text.ElideRight; Layout.maximumWidth: 180 }
}
