// Shared colors, fonts and sizes. Colors come from matugen (colors.json)
// and update live whenever matugen rewrites the file.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Last scheme that parsed correctly; a half-written file keeps the previous one.
    // (Named "scheme", not "palette": Item already has a palette property in Qt 6.)
    property var scheme: ({})
    // False until the first colors.json is read, so the shell does not fade in
    // from the fallback colors at startup; later changes animate (mode switches).
    property bool ready: false
    readonly property int colorFade: 500

    // Returns the matugen color for key, or the fallback until colors.json exists.
    // Reading root.scheme inside the function makes every color binding update with it.
    function pick(key, fallback) {
        const value = root.scheme[key];
        return (typeof value === "string" && value.length > 0) ? value : fallback;
    }

    // Material 3 roles. The on_* roles are named *Text here, because names that
    // start with "on" + capital letter are the QML signal-handler pattern.
    // Not readonly: a Behavior below fades each one to its new value.
    property color surface:                       pick("surface", "#11131a")
    property color surfaceContainer:              pick("surface_container", "#1d2027")
    property color surfaceContainerHigh:          pick("surface_container_high", "#272a31")
    property color surfaceText:                   pick("on_surface", "#e1e2eb")
    property color surfaceTextMuted:              pick("on_surface_variant", "#c4c6d0")
    property color primary:                       pick("primary", "#adc6ff")
    property color primaryText:                   pick("on_primary", "#102f60")
    property color tertiary:                      pick("tertiary", "#ddbce0")
    property color error:                         pick("error", "#ffb4ab")
    property color outline:                       pick("outline", "#8e9099")
    property color outlineVariant:                pick("outline_variant", "#44474f")

    Behavior on surface { enabled: root.ready; ColorAnimation { duration: root.colorFade } }
    Behavior on surfaceContainer { enabled: root.ready; ColorAnimation { duration: root.colorFade } }
    Behavior on surfaceContainerHigh { enabled: root.ready; ColorAnimation { duration: root.colorFade } }
    Behavior on surfaceText { enabled: root.ready; ColorAnimation { duration: root.colorFade } }
    Behavior on surfaceTextMuted { enabled: root.ready; ColorAnimation { duration: root.colorFade } }
    Behavior on primary { enabled: root.ready; ColorAnimation { duration: root.colorFade } }
    Behavior on primaryText { enabled: root.ready; ColorAnimation { duration: root.colorFade } }
    Behavior on tertiary { enabled: root.ready; ColorAnimation { duration: root.colorFade } }
    Behavior on error { enabled: root.ready; ColorAnimation { duration: root.colorFade } }
    Behavior on outline { enabled: root.ready; ColorAnimation { duration: root.colorFade } }
    Behavior on outlineVariant { enabled: root.ready; ColorAnimation { duration: root.colorFade } }

    // Geometry follows Hyprland: gaps_out = 8, rounding = 12.
    readonly property int gap: 8
    readonly property int radius: 12
    readonly property int barHeight: 32                 // height of every bar island

    readonly property int pillHeight: barHeight - 8    // 24 px: workspace chips, 4 px of glass around them
    readonly property int spacing: 6                    // inside the islands

    // Text in IBM Plex Sans; numbers, times and commands in Maple Mono, whose equal-width
    // digits keep values from shifting the layout as they change.
    readonly property string fontFamily: "IBM Plex Sans"
    readonly property string monoFamily: "Maple Mono NF"
    readonly property int fontSize: 12
    // Variable icon font from ttf-material-symbols-variable; icons are typed by name (ligatures).
    readonly property string iconFamily: "Material Symbols Rounded"
    readonly property int iconSize: 17

    FileView {
        id: colorsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
        blockLoading: true          // colors are ready before the bar is drawn
        watchChanges: true          // fileChanged() fires when matugen rewrites the file
        onFileChanged: reload()
        onLoaded: {
            try {
                root.scheme = JSON.parse(text());
                root.ready = true;
                console.info("Theme: loaded colors.json, text color", root.surfaceText);
            } catch (e) {
                console.warn("Theme: colors.json could not be parsed, keeping the previous colors");
            }
        }
    }
}
