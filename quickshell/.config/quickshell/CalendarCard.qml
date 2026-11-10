// Large clock with seconds above a month view, weeks starting on Monday, today
// highlighted. Arrows or scroll change the month; clicking the title returns to today.
import QtQuick
import QtQuick.Layouts
import Quickshell

Card {
    id: root

    SystemClock { id: clock; precision: SystemClock.Hours }
    // Seconds tick only while the card is on screen (the popup passes its open state).
    property bool live: true
    SystemClock { id: now; precision: SystemClock.Seconds; enabled: root.live }

    readonly property date today: clock.date
    property int monthOffset: 0                 // 0 = current month
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)

    // 42 cells (6 weeks) starting from the Monday on or before the 1st.
    readonly property var cells: {
        const lead = (shown.getDay() + 6) % 7;            // Sunday = 0 in JS, Monday first here
        return Array.from({ length: 42 }, (_, i) =>
            new Date(shown.getFullYear(), shown.getMonth(), 1 - lead + i));
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    // 17:43 large, :08 small on the same baseline, the full date under them.
    Row {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 4

        Label {
            id: hhmm
            text: Qt.formatTime(now.date, "HH:mm")
            font.family: Theme.monoFamily
            font.pixelSize: 52
            font.weight: Font.Light
        }
        Label {
            text: Qt.formatTime(now.date, ":ss")
            font.family: Theme.monoFamily
            font.pixelSize: 20
            color: Theme.primary
            // Text items align by height; move the small one down to the large one's baseline.
            y: hhmm.baselineOffset - baselineOffset
        }
    }
    Label {
        text: Qt.formatDate(now.date, "dddd d MMMM")
        color: Theme.surfaceTextMuted
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 6
    }

    RowLayout {
        MaterialIcon {
            icon: "chevron_left"
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.monthOffset-- }
        }
        Label {
            text: Qt.formatDate(root.shown, "MMMM yyyy")
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.monthOffset = 0 }
        }
        MaterialIcon {
            icon: "chevron_right"
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.monthOffset++ }
        }
    }

    GridLayout {
        columns: 7
        rowSpacing: 2
        columnSpacing: 2
        Layout.fillWidth: true

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            Label {
                required property string modelData
                text: modelData
                color: Theme.surfaceTextMuted
                font.pixelSize: Theme.fontSize - 1
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }

        Repeater {
            model: root.cells

            Rectangle {
                required property var modelData
                readonly property bool isToday: root.sameDay(modelData, root.today)
                readonly property bool inMonth: modelData.getMonth() === root.shown.getMonth()

                Layout.fillWidth: true
                implicitHeight: 30
                radius: 15
                color: isToday ? Theme.primary : "transparent"

                Label {
                    anchors.centerIn: parent
                    text: modelData.getDate()
                    color: parent.isToday ? Theme.primaryText
                         : parent.inMonth ? Theme.surfaceText
                         : Qt.alpha(Theme.surfaceTextMuted, 0.5)
                    font.weight: parent.isToday ? Font.Bold : Font.Normal
                }
            }
        }
    }

    // Scroll anywhere on the calendar to change month.
    WheelHandler {
        onWheel: event => root.monthOffset += event.angleDelta.y > 0 ? -1 : 1
    }
}
