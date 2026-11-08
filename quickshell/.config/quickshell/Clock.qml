// Time and date; updates once per minute. Click: calendar popup.
import QtQuick
import Quickshell

Pill {
    id: root

    onClicked: CalendarState.toggle()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    MaterialIcon { icon: "schedule"; color: Theme.primary }
    Label {
        text: Qt.formatDateTime(clock.date, "HH:mm  ·  ddd d MMM")
        font.family: Theme.monoFamily
        font.weight: Font.Medium
    }
}
