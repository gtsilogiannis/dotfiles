// SwayNC state. Left click: notification panel, right click: Do Not Disturb.
// swaync-client -swb prints one JSON line per change, e.g. {"alt": "dnd-notification", ...}.
import QtQuick
import Quickshell
import Quickshell.Io

Stat {
    id: root

    property string swayncState: "none"       // none | notification | dnd-none | dnd-notification | inhibited-*
    property int count: 0

    readonly property bool dnd: swayncState.startsWith("dnd")
    readonly property bool unread: swayncState.endsWith("notification")

    icon: dnd ? "notifications_off" : unread ? "notifications_unread" : "notifications"
    filled: unread
    value: count > 0 ? String(count) : ""
    accent: dnd ? Theme.surfaceTextMuted : Theme.primary

    onClicked: mouse => Quickshell.execDetached(
        mouse.button === Qt.RightButton ? ["swaync-client", "-d", "-sw"] : ["swaync-client", "-t", "-sw"])

    Process {
        running: true
        command: ["swaync-client", "-swb"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const data = JSON.parse(line);
                    root.swayncState = data.alt ?? "none";
                    root.count = parseInt(data.text) || 0;
                } catch (e) {}
            }
        }
    }
}
