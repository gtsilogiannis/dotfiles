// Time and date; updates once per minute.
import QtQuick
import Quickshell

Pill {
    id: root

    interactive: false

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    MaterialIcon { icon: "schedule"; color: Theme.primary }
    Label {
        text: Qt.formatDateTime(clock.date, "HH:mm  ·  ddd d MMM")
        font.weight: Font.Medium
    }
}
