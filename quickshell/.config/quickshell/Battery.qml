// Battery in the iOS 27 style: no outline, a track with the charge level filled
// in from the left, and the percentage (plus a glyph) inside the shape. Colors
// come from matugen, like the rest of the bar:
//   on battery          primary fill
//   plugged, held back  primary fill, plug glyph (conservation mode keeps ~80%)
//   charging            primary fill, bolt glyph
//   low (<= 20%)        error fill, on battery only
// The text is drawn twice and clipped: on_primary where it lies over the fill,
// the normal text color over the track, so it stays readable at any level.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Item {
    id: root

    // UPower's aggregate device; percentage is 0..1 in Quickshell.
    readonly property var device: UPower.displayDevice
    readonly property real level: Math.max(0, Math.min(1, device.percentage))
    readonly property int percent: Math.round(level * 100)
    readonly property bool plugged: !UPower.onBattery
    readonly property bool charging: device.state === UPowerDeviceState.Charging
    readonly property bool low: !plugged && percent <= 20
    readonly property string glyph: charging ? "bolt" : plugged ? "power" : ""
    property bool conservation: false       // read from sysfs when the hint opens

    // Not readonly, so the Behaviors below can animate state changes.
    property color fillColor: low ? Theme.error : Theme.primary
    property color fillText: low ? Theme.surface : Theme.primaryText
    Behavior on fillColor { ColorAnimation { duration: 250 } }
    Behavior on fillText  { ColorAnimation { duration: 250 } }

    readonly property color trackColor: Qt.alpha(Theme.primary, 0.25)
    readonly property color trackText: Theme.surfaceText

    // "1h 20m" / "35m" from seconds.
    function duration(seconds) {
        const m = Math.round(seconds / 60);
        return m >= 60 ? `${Math.floor(m / 60)}h ${m % 60}m` : `${m}m`;
    }

    readonly property string hint: {
        if (charging)
            return `${percent}% · Charging` + (device.timeToFull > 0 ? ` · full in ${duration(device.timeToFull)}` : "");
        if (plugged)
            return `${percent}% · Plugged in, not charging` + (conservation ? " · Conservation mode" : "");
        return `${percent}% · On battery` + (device.timeToEmpty > 0 ? ` · ${duration(device.timeToEmpty)} left` : "");
    }

    visible: device.ready
    implicitWidth: body.width + 1 + nub.width
    implicitHeight: body.height
    Layout.leftMargin: 4                    // no pill around it, so keep some air
    Layout.rightMargin: 4

    // Number and glyph, instantiated once per color. Inline components do not see
    // the ids of this file, so everything they show is passed in.
    component Content: Row {
        property color tint
        property int percent
        property string glyph
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.percent
            color: parent.tint
            font.family: Theme.monoFamily
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: -0.5
        }

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            icon: parent.glyph
            visible: parent.glyph !== ""
            filled: true
            color: parent.tint
            font.pixelSize: 10
        }
    }

    Rectangle {
        id: body
        width: 30
        height: 14
        radius: 5
        color: root.trackColor

        // Text over the empty part of the track.
        Item {
            x: fill.width
            width: body.width - fill.width
            height: body.height
            clip: true
            Content {
                tint: root.trackText; percent: root.percent; glyph: root.glyph
                x: (body.width - width) / 2 - parent.x      // centered in the body, not in this clip
            }
        }

        // Charge level: a full-size rounded shape cut at the level, so the left end
        // keeps the body's corners and the right end is straight, as on iOS.
        Item {
            id: fill
            width: body.width * root.level
            height: body.height
            clip: true
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            Rectangle {
                width: body.width
                height: body.height
                radius: body.radius
                color: root.fillColor
            }

            Content {
                tint: root.fillText; percent: root.percent; glyph: root.glyph
                x: (body.width - width) / 2
            }
        }
    }

    Rectangle {             // positive terminal
        id: nub
        anchors { left: body.right; leftMargin: 1; verticalCenter: body.verticalCenter }
        width: 2
        height: 5
        radius: 1
        color: root.trackColor
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onContainsMouseChanged: if (containsMouse && consPath.found !== "") consFile.reload()
    }

    Tooltip {
        target: root
        hovered: area.containsMouse
        text: root.hint
    }

    // ideapad_laptop exposes the conservation switch on the VPC2004 platform device;
    // resolve the path once instead of hard-coding the PCI path.
    Process {
        id: consPath
        property string found: ""
        running: true
        command: ["sh", "-c", "ls /sys/bus/platform/devices/VPC2004:*/conservation_mode 2>/dev/null | head -n 1"]
        stdout: StdioCollector { onStreamFinished: consPath.found = text.trim() }
    }

    FileView {
        id: consFile
        path: consPath.found
        onLoaded: root.conservation = text().trim() === "1"
    }
}
