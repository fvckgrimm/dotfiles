pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick


// NotificationService — wraps NotificationServer.
// Lives at ShellRoot scope so it persists across reloads.
// Bar and popups connect to `notifications` list and `newNotification` signal.
Scope {
    id: root

    // Public API
    property var notifications: []   // newest-first history list, max 50
    property int unreadCount: 0

    signal newNotification(var notif)

    // The actual D-Bus server
    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true

        onNotification: notif => {
            // Must set tracked=true or Quickshell discards it immediately
            notif.tracked = true

            var n = {
                id:      notif.id,
                appName: notif.appName,
                summary: notif.summary,
                body:    notif.body,
                icon:    notif.appIcon,
                urgency: notif.urgency,
                time:    Qt.formatTime(new Date(), "hh:mm"),
                raw:     notif
            }

            var list = root.notifications.slice()
            list.unshift(n)
            if (list.length > 50) list.pop()
            root.notifications = list
            root.unreadCount++

            root.newNotification(n)
        }
    }

    function dismiss(notifObj) {
        if (notifObj.raw) notifObj.raw.dismiss()
        var list = root.notifications.filter(n => n.id !== notifObj.id)
        root.notifications = list
        root.unreadCount = Math.max(0, root.unreadCount - 1)
    }

    function clearAll() {
        // Dismiss all tracked notifications from the server
        for (var i = 0; i < root.notifications.length; i++) {
            var n = root.notifications[i]
            if (n.raw) n.raw.dismiss()
        }
        root.notifications = []
        root.unreadCount = 0
    }

    function markAllRead() {
        root.unreadCount = 0
    }
}
