// One notification: app icon and name, age, summary, body, action buttons.
// Used by the popups (with a timeout) and by the control center history.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Rectangle {
    id: card

    required property var notification
    property bool popup: false

    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property var defaultAction: notification.actions.find(a => a.identifier === "default") ?? null
    readonly property var buttons: notification.actions.filter(a => a.identifier !== "default")

    implicitHeight: content.implicitHeight + 24
    radius: 16
    color: Qt.alpha(popup ? Theme.surface : Theme.surfaceContainer, popup ? 0.8 : 0.7)
    border.width: 1
    border.color: critical ? Theme.error : Qt.alpha(Theme.outlineVariant, 0.6)

    // Popups disappear after the sender's timeout (6 s if it gives none) but stay
    // in the history. Critical ones stay until closed. Hovering pauses the timer.
    Timer {
        running: card.popup && !card.critical && !hover.containsMouse
        interval: card.notification.expireTimeout > 0 ? card.notification.expireTimeout * 1000 : 6000
        onTriggered: NotificationService.removePopup(card.notification)
    }

    // Updates the age label once per minute.
    property real now: Date.now()
    Timer { interval: 60000; running: !card.popup; repeat: true; onTriggered: card.now = Date.now() }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: card.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (card.defaultAction) card.defaultAction.invoke()
    }

    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 6

        RowLayout {
            spacing: 8

            IconImage {
                implicitSize: 18
                mipmap: true
                // The icon the sender gave, else the one of its desktop entry.
                source: card.notification.appIcon !== ""
                    ? Quickshell.iconPath(card.notification.appIcon, "dialog-information")
                    : Apps.icon(card.notification.desktopEntry || card.notification.appName)
            }
            Label {
                text: card.notification.appName || "Notification"
                color: Theme.surfaceTextMuted
                font.pixelSize: Theme.fontSize - 1
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Label {
                text: NotificationService.age(card.notification, card.now)
                color: Theme.surfaceTextMuted
                font.pixelSize: Theme.fontSize - 1
            }
            MaterialIcon {
                icon: "close"
                font.pixelSize: 16
                color: closeArea.containsMouse ? Theme.error : Theme.surfaceTextMuted
                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.notification.dismiss()
                }
            }
        }

        RowLayout {
            spacing: 10

            Image {         // picture sent with the notification (album art, avatar, screenshot)
                visible: card.notification.image !== ""
                source: card.notification.image
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: card.notification.summary
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Label {
                    visible: text !== ""
                    text: card.notification.body
                    textFormat: Text.PlainText
                    color: Theme.surfaceTextMuted
                    wrapMode: Text.Wrap
                    maximumLineCount: card.popup ? 3 : 5
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        RowLayout {
            visible: card.buttons.length > 0
            spacing: 6

            Repeater {
                model: card.buttons

                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 28
                    radius: 14
                    color: actionArea.containsMouse ? Qt.alpha(Theme.primary, 0.3) : Qt.alpha(Theme.primary, 0.15)

                    Label {
                        anchors.centerIn: parent
                        text: modelData.text
                        color: Theme.primary
                        font.pixelSize: Theme.fontSize - 1
                    }
                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
