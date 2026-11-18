// Notification daemon. Everything stays in the history until dismissed; popups
// are hidden by Do Not Disturb, except critical ones.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    property var popups: []                 // newest first, at most 5 on screen
    property var times: ({})                // arrival time (ms) by notification id

    readonly property var history: server.trackedNotifications.values

    function removePopup(notification) {
        root.popups = root.popups.filter(n => n !== notification);
    }

    function clearAll() {
        for (const n of [...root.history]) n.dismiss();
    }

    // "now", "5m", "2h", or the date for older ones.
    function age(notification, now) {
        const t = root.times[notification.id];
        if (t === undefined) return "";
        const minutes = Math.floor((now - t) / 60000);
        if (minutes < 1) return "now";
        if (minutes < 60) return `${minutes}m`;
        if (minutes < 1440) return `${Math.floor(minutes / 60)}h`;
        return Qt.formatDate(new Date(t), "d MMM");
    }

    NotificationServer {
        id: server

        keepOnReload: true          // a shell reload keeps the history
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;            // keep it instead of discarding it
            root.times = Object.assign({}, root.times, { [notification.id]: Date.now() });
            notification.closed.connect(() => root.removePopup(notification));

            // Notifications re-emitted after a reload are already in the history.
            const quiet = root.dnd && notification.urgency !== NotificationUrgency.Critical;
            if (!quiet && !notification.lastGeneration)
                root.popups = [notification, ...root.popups].slice(0, 5);
        }
    }

    // qs ipc call notifications toggleDnd | setDnd <true|false> | getDnd | clear
    IpcHandler {
        target: "notifications"
        function toggleDnd(): void { root.dnd = !root.dnd; }
        function setDnd(on: bool): void { root.dnd = on; }      // used by mode.sh
        function getDnd(): bool { return root.dnd; }
        function clear(): void { root.clearAll(); }
    }
}
