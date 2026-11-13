// Depth wallpaper: draws the wallpaper, a large clock and then the subject cut
// out of the same picture (scripts/make-depth.sh), so that the subject stands
// in front of the clock. Lives on the bottom layer: above awww, below every
// window. Exists only while the current wallpaper is in
// ~/Pictures/wallpapers/depth/, its cutout has been made, and the desktop is
// in browsing mode; otherwise no window is created and nothing is loaded.
//
// The wallpaper is drawn here too, through the same transform as the cutout
// (cover the screen, centered, like awww), so the two line up exactly.
//
// <name>.depth.json may hold an optional "clock" object, read live:
//   x         center of the clock, fraction of the screen width (0.5)
//   baseline  baseline of the time, fraction of the screen height
//             (default: 30% of the clock size below the top of the subject,
//             so the subject covers the lower part of the digits)
//   size      height of the time font, fraction of the screen height (0.2)
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    readonly property string depthDir: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/depth"
    readonly property string clockFamily: "Inter Display"

    property string wallpaper: ""
    readonly property bool isDepth: root.wallpaper.indexOf("/wallpapers/depth/") >= 0
    readonly property string stem: root.wallpaper.split("/").pop().replace(/\.[^.]*$/, "")
    property var meta: null                     // parsed .depth.json, null without a cutout
    readonly property bool active: root.isDepth && root.meta !== null && !ModeState.focus

    onWallpaperChanged: root.meta = null

    // Written in place by set-wallpaper.sh on every change.
    FileView {
        id: pathFile
        property bool read: false
        path: Quickshell.env("HOME") + "/.cache/current_wallpaper.path"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            read = true;
            root.wallpaper = text().trim();
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: !pathFile.read
        onTriggered: pathFile.reload()
    }

    FileView {
        path: root.isDepth ? root.depthDir + "/" + root.stem + ".depth.json" : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const m = JSON.parse(text());
                root.meta = m.width > 0 && m.height > 0 && m.cutout ? m : null;
            } catch (e) {
                root.meta = null;
            }
        }
        onLoadFailed: root.meta = null
    }

    Variants {
        model: root.active ? Quickshell.screens : []

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore     // the whole screen, like the wallpaper under it
            color: "transparent"
            mask: Region {}                         // never takes input
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell-desktop"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            readonly property var meta: root.meta
            readonly property var cut: meta.cutout
            readonly property var clockPreset: meta.clock ?? ({})

            // Cover: scale until both sides fill the screen, center, crop the rest.
            readonly property real s: Math.max(width / meta.width, height / meta.height)
            readonly property real ox: (width - meta.width * s) / 2
            readonly property real oy: (height - meta.height * s) / 2

            readonly property real clockSize: Math.round(height * (clockPreset.size ?? 0.2))
            readonly property real clockBaseline: clockPreset.baseline !== undefined
                ? height * clockPreset.baseline
                : oy + cut.y * s + 0.3 * clockSize

            // Lets awww finish growing the new wallpaper before covering it.
            Timer {
                id: settle
                interval: 1200
                running: true
            }

            Item {
                id: scene
                anchors.fill: parent
                opacity: !settle.running && back.status === Image.Ready && front.status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                // Decoded at the size it is shown: no larger texture than the screen needs.
                Image {
                    id: back
                    x: Math.round(win.ox)
                    y: Math.round(win.oy)
                    width: Math.round(win.meta.width * win.s)
                    height: Math.round(win.meta.height * win.s)
                    sourceSize.width: width
                    sourceSize.height: height
                    source: "file://" + root.wallpaper
                    fillMode: Image.Stretch
                    autoTransform: true
                    asynchronous: true
                }

                SystemClock {
                    id: clock
                    precision: SystemClock.Minutes
                }

                Text {
                    id: time
                    x: Math.round(win.width * (win.clockPreset.x ?? 0.5) - width / 2)
                    y: Math.round(win.clockBaseline - baselineOffset)
                    text: Qt.formatTime(clock.date, "HH:mm")
                    color: Theme.surfaceText
                    font.family: root.clockFamily
                    font.pixelSize: win.clockSize
                    font.weight: Font.Light
                    font.features: { "tnum": 1 }    // equal-width digits: the clock does not shift each minute
                    renderType: Text.CurveRendering
                }

                Text {
                    x: Math.round(time.x + (time.width - width) / 2)
                    y: Math.round(time.y + time.baselineOffset - win.clockSize * 0.78 - height)
                    text: Qt.formatDate(clock.date, "dddd d MMMM")
                    color: Theme.primary
                    font.family: root.clockFamily
                    font.pixelSize: Math.round(win.clockSize * 0.11)
                    font.weight: Font.Normal
                    font.letterSpacing: Math.round(win.clockSize * 0.11) * 0.08
                }

                Image {
                    id: front
                    x: Math.round(win.ox + win.cut.x * win.s)
                    y: Math.round(win.oy + win.cut.y * win.s)
                    width: Math.round(win.cut.width * win.s)
                    height: Math.round(win.cut.height * win.s)
                    sourceSize.width: width
                    sourceSize.height: height
                    source: "file://" + root.depthDir + "/" + root.stem + ".depth.png"
                    fillMode: Image.Stretch
                    autoTransform: true
                    asynchronous: true
                }
            }
        }
    }
}
