// Month card on the depth desktop, frosted glass, today in the accent.
// Only the rows the month needs; no input.
import QtQuick
import Quickshell

Item {
    id: root

    required property Item backdrop             // the wallpaper Image of the desktop layer

    readonly property int pad: 14
    readonly property int cell: 32              // width of a day column
    readonly property int rowHeight: 28

    SystemClock { id: clock; precision: SystemClock.Hours }   // enough to turn the day at midnight
    readonly property date today: clock.date
    readonly property int year: today.getFullYear()
    readonly property int month: today.getMonth()
    readonly property int lead: (new Date(year, month, 1).getDay() + 6) % 7    // Sunday = 0 in JS, Monday first here
    readonly property int days: new Date(year, month + 1, 0).getDate()
    readonly property int weeks: Math.ceil((lead + days) / 7)

    implicitWidth: 7 * cell + 2 * pad
    implicitHeight: pad + header.height + 8 + names.height + 4 + weeks * rowHeight + pad - 4

    DesktopGlass { backdrop: root.backdrop }

    // Month name, and the year in the accent
    Item {
        id: header
        x: root.pad + 4
        y: root.pad
        width: root.width - 2 * root.pad - 8
        height: monthName.implicitHeight

        Label {
            id: monthName
            text: Qt.formatDate(root.today, "MMMM")
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }
        Label {
            anchors.right: parent.right
            anchors.baseline: monthName.baseline
            text: root.year
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Theme.primary
        }
    }

    Row {
        id: names
        x: root.pad
        y: header.y + header.height + 8

        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            Label {
                required property string modelData
                required property int index
                width: root.cell
                text: modelData
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Theme.surfaceTextMuted
                opacity: index >= 5 ? 0.6 : 1       // weekend
            }
        }
    }

    Grid {
        x: root.pad
        y: names.y + names.height + 4
        columns: 7

        Repeater {
            model: root.weeks * 7

            Item {
                required property int index
                readonly property int day: index - root.lead + 1
                readonly property bool inMonth: day >= 1 && day <= root.days
                readonly property bool isToday: day === root.today.getDate()

                width: root.cell
                height: root.rowHeight

                Rectangle {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    radius: 13
                    visible: parent.inMonth && parent.isToday
                    color: Theme.primary
                }
                Label {
                    anchors.centerIn: parent
                    visible: parent.inMonth
                    text: parent.day
                    font.pixelSize: 13
                    font.weight: parent.isToday ? Font.Bold : Font.Normal
                    color: parent.isToday ? Theme.primaryText : Theme.surfaceText
                    opacity: parent.isToday || parent.index % 7 < 5 ? 1 : 0.6
                }
            }
        }
    }
}
