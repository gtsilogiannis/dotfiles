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

    // Returns the matugen color for key, or the fallback until colors.json exists.
    // Reading root.scheme inside the function makes every color binding update with it.
    function pick(key, fallback) {
        const value = root.scheme[key];
        return (typeof value === "string" && value.length > 0) ? value : fallback;
    }

    // Material 3 roles. The on_* roles are named *Text here, because names that
    // start with "on" + capital letter are the QML signal-handler pattern.
    readonly property color surface:              pick("surface", "#11131a")
    readonly property color surfaceContainer:     pick("surface_container", "#1d2027")
    readonly property color surfaceContainerHigh: pick("surface_container_high", "#272a31")
    readonly property color surfaceText:          pick("on_surface", "#e1e2eb")
    readonly property color surfaceTextMuted:     pick("on_surface_variant", "#c4c6d0")
    readonly property color primary:              pick("primary", "#adc6ff")
    readonly property color primaryText:          pick("on_primary", "#102f60")
    readonly property color tertiary:             pick("tertiary", "#ddbce0")
    readonly property color error:                pick("error", "#ffb4ab")
    readonly property color outline:              pick("outline", "#8e9099")
    readonly property color outlineVariant:       pick("outline_variant", "#44474f")

    // Geometry follows Hyprland: gaps_out = 8, rounding = 12.
    readonly property int gap: 8
    readonly property int radius: 12
    readonly property int barHeight: 34

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 11

    FileView {
        id: colorsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
        blockLoading: true          // colors are ready before the bar is drawn
        watchChanges: true          // fileChanged() fires when matugen rewrites the file
        onFileChanged: reload()
        onLoaded: {
            try {
                root.scheme = JSON.parse(text());
                console.info("Theme: loaded colors.json, text color", root.surfaceText);
            } catch (e) {
                console.warn("Theme: colors.json could not be parsed, keeping the previous colors");
            }
        }
    }
}
