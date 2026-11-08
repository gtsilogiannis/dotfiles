// Pill with an icon and a value, e.g. [thermostat] 45°.
import QtQuick

Pill {
    id: stat

    property string icon
    property string value
    property bool filled: false
    property color accent: Theme.primary        // icon color; Theme.error for warnings

    MaterialIcon { icon: stat.icon; filled: stat.filled; color: stat.accent }
    Label { text: stat.value; visible: stat.value !== ""; font.family: Theme.monoFamily }
}
