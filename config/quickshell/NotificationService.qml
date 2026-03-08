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
        // Try to dismiss each from server, but never let a failure block the clear
        var copy = root.notifications.slice()
        for (var i = 0; i < copy.length; i++) {
            try { if (copy[i].raw) copy[i].raw.dismiss() } catch(e) {}
        }
        root.notifications = []
        root.unreadCount = 0
    }

    function markAllRead() {
        root.unreadCount = 0
    }
}
