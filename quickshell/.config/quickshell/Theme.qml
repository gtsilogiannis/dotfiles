// Shared colors, fonts and sizes. Colors come from matugen (colors.json)
// and update live whenever matugen rewrites the file.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Last palette that parsed correctly; a half-written file keeps the previous one.
    property var palette: ({})

    // Fallbacks are used until colors.json exists (first run before matugen).
    readonly property color surface:              palette.surface ?? "#11131a"
    readonly property color surfaceContainer:     palette.surface_container ?? "#1d2027"
    readonly property color surfaceContainerHigh: palette.surface_container_high ?? "#272a31"
    readonly property color onSurface:            palette.on_surface ?? "#e1e2eb"
    readonly property color onSurfaceVariant:     palette.on_surface_variant ?? "#c4c6d0"
    readonly property color primary:              palette.primary ?? "#adc6ff"
    readonly property color onPrimary:            palette.on_primary ?? "#102f60"
    readonly property color tertiary:             palette.tertiary ?? "#ddbce0"
    readonly property color error:                palette.error ?? "#ffb4ab"
    readonly property color outline:              palette.outline ?? "#8e9099"
    readonly property color outlineVariant:       palette.outline_variant ?? "#44474f"

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
                root.palette = JSON.parse(text());
            } catch (e) {
                console.warn("Theme: colors.json could not be parsed, keeping the previous palette");
            }
        }
    }
}
