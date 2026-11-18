// Depth desktop on the bottom layer: wallpaper, clock, the subject cut out of the
// same picture, then the cards. Wallpaper and cutout share one transform to line up.
// Loaded only while DepthState.active.
//
// Optional keys of <name>.depth.json, read live. "clock":
//   x         center of the clock, fraction of the screen width (0.5)
//   top       top of the digits, fraction of the screen height (0.09)
//   size      base font size, fraction of the screen height (0.2)
//   stretch   font size as a multiple of the base size. Default: adapts to
//             the subject, as tall as possible (up to 1.8) while the highest
//             point of the subject covers at most 35% of the digits, and
//             never wider than 36% of the screen
//   baseline  baseline of the time, fraction of the screen height; when
//             set it wins over top
// "media", the player card (DesktopMedia.qml):
//   x, y      top left corner, fractions of the screen (0.03, bottom 0.06)
// "stack", the month and to-do cards in the bottom right corner:
//   right     gap to the right edge, fraction of the screen width (0.03)
//   bottom    gap to the bottom edge, fraction of the screen height (0.06)
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    // Roboto Flex, black and narrow: tall digits without stretched glyphs
    readonly property string clockFamily: "Roboto Flex"
    readonly property var clockAxes: ({ "wght": 900, "wdth": 30, "opsz": 144, "YTFI": 788 })
    readonly property var dateAxes: ({ "wght": 700, "opsz": 28 })

    Variants {
        model: DepthState.active ? Quickshell.screens : []

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore     // the whole screen, like the wallpaper under it
            color: "transparent"
            // Input only on the media and to-do cards
            mask: Region {
                Region { item: media.shown ? media : null; radius: Theme.radius * 2 }
                Region { item: todo; radius: Theme.radius * 2 }
            }
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell-desktop"
            // Exclusive keyboard only while a task is typed, so no second click is needed
            WlrLayershell.keyboardFocus: todo.editing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            readonly property var meta: DepthState.meta
            readonly property var cut: meta.cutout
            readonly property var clockPreset: meta.clock ?? ({})
            readonly property var mediaPreset: meta.media ?? ({})
            readonly property var stackPreset: meta.stack ?? ({})

            // Cover: scale until both sides fill the screen, center, crop the rest.
            readonly property real s: Math.max(width / meta.width, height / meta.height)
            readonly property real ox: (width - meta.width * s) / 2
            readonly property real oy: (height - meta.height * s) / 2

            readonly property real baseSize: Math.round(height * (clockPreset.size ?? 0.2))
            readonly property real clockTop: height * (clockPreset.top ?? 0.09)
            readonly property real subjectTop: oy + cut.y * s
            // Measured at 100 px, so they do not depend on the size they decide
            readonly property real digitRatio: digits.tightBoundingRect.height / 100
            readonly property real widthRatio: sample.advanceWidth / 100
            readonly property real stretch: clockPreset.stretch
                ?? Math.max(1.0, Math.min(1.8, (subjectTop - clockTop) / (0.65 * baseSize * digitRatio)))
            readonly property real clockSize: Math.round(Math.min(baseSize * stretch, width * 0.36 / widthRatio))
            readonly property real digitHeight: clockSize * digitRatio
            readonly property real clockBaseline: clockPreset.baseline !== undefined
                ? height * clockPreset.baseline
                : clockTop + digitHeight

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
                    source: "file://" + DepthState.wallpaper
                    fillMode: Image.Stretch
                    autoTransform: true
                    asynchronous: true
                }

                SystemClock {
                    id: clock
                    precision: SystemClock.Minutes
                }

                TextMetrics {
                    id: digits
                    font.family: root.clockFamily
                    font.pixelSize: 100
                    font.variableAxes: root.clockAxes
                    text: "0123456789"
                }

                TextMetrics {
                    id: sample
                    font.family: root.clockFamily
                    font.pixelSize: 100
                    font.variableAxes: root.clockAxes
                    font.features: { "tnum": 1 }
                    text: "00:00"
                }

                Text {
                    id: time
                    x: Math.round(win.width * (win.clockPreset.x ?? 0.5) - width / 2)
                    y: Math.round(win.clockBaseline - baselineOffset)
                    text: Qt.formatTime(clock.date, "HH:mm")
                    color: Theme.surfaceText
                    font.family: root.clockFamily
                    font.pixelSize: win.clockSize
                    font.variableAxes: root.clockAxes
                    font.features: { "tnum": 1 }    // equal-width digits: the clock does not shift each minute
                    renderType: Text.CurveRendering
                }

                Text {
                    x: Math.round(time.x + (time.width - width) / 2)
                    y: Math.round(win.clockBaseline - win.digitHeight - win.baseSize * 0.08 - height)
                    text: Qt.formatDate(clock.date, "dddd d MMMM")
                    color: Theme.primary
                    font.family: root.clockFamily
                    font.pixelSize: Math.round(win.baseSize * 0.12)
                    font.variableAxes: root.dateAxes
                    font.letterSpacing: Math.round(win.baseSize * 0.12) * 0.01
                }

                Image {
                    id: front
                    x: Math.round(win.ox + win.cut.x * win.s)
                    y: Math.round(win.oy + win.cut.y * win.s)
                    width: Math.round(win.cut.width * win.s)
                    height: Math.round(win.cut.height * win.s)
                    sourceSize.width: width
                    sourceSize.height: height
                    source: "file://" + DepthState.depthDir + "/" + DepthState.stem + ".depth.png"
                    fillMode: Image.Stretch
                    autoTransform: true
                    asynchronous: true
                }

                // In front of the subject, like a widget on the glass.
                DesktopMedia {
                    id: media
                    backdrop: back
                    x: Math.round(win.width * (win.mediaPreset.x ?? 0.03))
                    y: Math.round(win.mediaPreset.y !== undefined
                        ? win.height * win.mediaPreset.y
                        : win.height * (1 - 0.06) - height)
                }

                // The to-do list grows upwards and pushes the month with it
                DesktopTodo {
                    id: todo
                    backdrop: back
                    allowEditing: DepthState.shownOn(win.screen)
                    x: Math.round(win.width * (1 - (win.stackPreset.right ?? 0.03)) - width)
                    y: Math.round(win.height * (1 - (win.stackPreset.bottom ?? 0.06)) - height)
                }

                DesktopCalendar {
                    backdrop: back
                    x: todo.x
                    y: todo.y - Theme.gap * 1.5 - height
                }
            }
        }
    }
}
