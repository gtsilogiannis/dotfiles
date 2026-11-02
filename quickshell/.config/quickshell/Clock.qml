// Time and date; updates once per minute.
import QtQuick
import Quickshell

Text {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, "HH:mm  ·  ddd d MMM")
    color: Theme.surfaceText
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize + 2
    font.weight: Font.Medium
}
