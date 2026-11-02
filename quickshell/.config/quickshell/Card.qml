// Rounded section of the control center.
import QtQuick
import QtQuick.Layouts

Rectangle {
    default property alias content: column.data
    property alias spacing: column.spacing

    implicitHeight: column.implicitHeight + 28
    radius: 16
    color: Qt.alpha(Theme.surfaceContainer, 0.7)

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 10
    }
}
