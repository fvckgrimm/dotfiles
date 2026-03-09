pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import QtQuick

Scope {
    id: root

    // ── Public API ────────────────────────────────────────────────────────────
    property var notifications: []       // newest-first history, max 50
    property var snoozed:       []       // { notif, until (ms epoch) }
    property int unreadCount:   0
    signal newNotification(var notif)    // fired even when DnD (popup suppresses itself)

    // ── Do Not Disturb ────────────────────────────────────────────────────────
    property bool dndEnabled:   false
    property bool dndScheduled: false    // auto-enable on a time window
    property int  dndStartHour: 22       // 24h
    property int  dndStartMin:  0
    property int  dndEndHour:   8
    property int  dndEndMin:    0

    // Computed: is DnD active right now (manual OR scheduled)?
    readonly property bool dndActive: {
        if (dndEnabled) return true
        if (!dndScheduled) return false
        var now = new Date()
        var h = now.getHours(), m = now.getMinutes()
        var cur   = h * 60 + m
        var start = dndStartHour * 60 + dndStartMin
        var end   = dndEndHour   * 60 + dndEndMin
        // Handle overnight ranges (e.g. 22:00 – 08:00)
        if (start > end)
            return cur >= start || cur < end
        return cur >= start && cur < end
    }

    // ── Per-app filtering ─────────────────────────────────────────────────────
    // filteredApps: set of appName strings whose notifications are silently dropped
    property var filteredApps: []

    function isFiltered(appName) {
        return root.filteredApps.indexOf(appName) !== -1
    }

    function filterApp(appName) {
        if (isFiltered(appName)) return
        var a = root.filteredApps.slice()
        a.push(appName)
        root.filteredApps = a
        _savePrefs()
    }

    function unfilterApp(appName) {
        root.filteredApps = root.filteredApps.filter(a => a !== appName)
        _savePrefs()
    }

    // ── Snooze ────────────────────────────────────────────────────────────────
    // minutes: 5 | 15 | 30 | 60
    function snooze(notifObj, minutes) {
        // Remove from active list
        root.notifications = root.notifications.filter(n => n.id !== notifObj.id)
        root.unreadCount   = Math.max(0, root.unreadCount - 1)

        var entry = { notif: notifObj, until: Date.now() + minutes * 60000 }
        var s = root.snoozed.slice()
        s.push(entry)
        root.snoozed = s
    }

    // Check snoozed items every 30 s
    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: {
            var now = Date.now()
            var still = []
            root.snoozed.forEach(e => {
                if (now >= e.until) {
                    // Re-surface
                    var list = root.notifications.slice()
                    list.unshift(e.notif)
                    if (list.length > 50) list.pop()
                    root.notifications = list
                    root.unreadCount++
                    root.newNotification(e.notif)
                } else {
                    still.push(e)
                }
            })
            root.snoozed = still
        }
    }

    // ── Actions ───────────────────────────────────────────────────────────────
    function invokeAction(notifObj, actionId) {
        if (notifObj.raw && notifObj.raw.actions) {
            var actions = notifObj.raw.actions
            for (var i = 0; i < actions.length; i++) {
                if (actions[i].identifier === actionId) {
                    actions[i].invoke()
                    break
                }
            }
        }
        dismiss(notifObj)
    }

    // ── Core CRUD ─────────────────────────────────────────────────────────────
    function dismiss(notifObj) {
        if (notifObj.raw) {
            try { notifObj.raw.dismiss() } catch(e) {}
        }
        root.notifications = root.notifications.filter(n => n.id !== notifObj.id)
        root.unreadCount   = Math.max(0, root.unreadCount - 1)
    }

    function clearAll() {
        root.notifications.forEach(n => {
            try { if (n.raw) n.raw.dismiss() } catch(e) {}
        })
        root.notifications = []
        root.unreadCount   = 0
    }

    function markAllRead() {
        root.unreadCount = 0
    }

    // ── Notification server ───────────────────────────────────────────────────
    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true

        onNotification: notif => {
            notif.tracked = true

            // Per-app filter — drop silently
            if (root.isFiltered(notif.appName)) return

            // Parse actions into a plain-JS list so QML delegates can read them
            var acts = []
            if (notif.actions) {
                for (var i = 0; i < notif.actions.length; i++) {
                    var a = notif.actions[i]
                    // Skip the generic "default" action — it fires on card click
                    if (a.identifier !== "default") {
                        acts.push({ id: a.identifier, label: a.text })
                    }
                }
            }

            var n = {
                id:      notif.id,
                appName: notif.appName,
                summary: notif.summary,
                body:    notif.body,
                icon:    notif.appIcon,
                urgency: notif.urgency,
                time:    Qt.formatTime(new Date(), "hh:mm"),
                actions: acts,
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

    // ── Persistence (prefs only — notifications are ephemeral) ───────────────
    function _savePrefs() {
        var prefs = {
            dndEnabled:   root.dndEnabled,
            dndScheduled: root.dndScheduled,
            dndStartHour: root.dndStartHour,
            dndStartMin:  root.dndStartMin,
            dndEndHour:   root.dndEndHour,
            dndEndMin:    root.dndEndMin,
            filteredApps: root.filteredApps
        }
        saveProc.running = false
        var json = JSON.stringify(prefs)
        saveProc.command = [
            "bash", "-c",
            "mkdir -p ~/.local/share && printf '%s' " +
            JSON.stringify(json).replace(/'/g, "'\\''") +
            " > ~/.local/share/qs-notif-prefs.json"
        ]
        saveProc.running = true
    }

    Process {
        id: saveProc
        running: false
    }

    Process {
        id: loadPrefs
        command: ["bash", "-c", "cat ~/.local/share/qs-notif-prefs.json 2>/dev/null || echo '{}'"]
        running: true
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var p = JSON.parse(data.trim())
                    if (p.dndEnabled   !== undefined) root.dndEnabled   = p.dndEnabled
                    if (p.dndScheduled !== undefined) root.dndScheduled = p.dndScheduled
                    if (p.dndStartHour !== undefined) root.dndStartHour = p.dndStartHour
                    if (p.dndStartMin  !== undefined) root.dndStartMin  = p.dndStartMin
                    if (p.dndEndHour   !== undefined) root.dndEndHour   = p.dndEndHour
                    if (p.dndEndMin    !== undefined) root.dndEndMin    = p.dndEndMin
                    if (p.filteredApps !== undefined) root.filteredApps = p.filteredApps
                } catch(e) {}
            }
        }
    }

    // Save whenever relevant prefs change
    onDndEnabledChanged:   _savePrefs()
    onDndScheduledChanged: _savePrefs()
    onDndStartHourChanged: _savePrefs()
    onDndStartMinChanged:  _savePrefs()
    onDndEndHourChanged:   _savePrefs()
    onDndEndMinChanged:    _savePrefs()

    // Re-evaluate scheduled DnD every minute
    Timer {
        interval: 60000
        repeat: true
        running: root.dndScheduled
        // dndActive is a computed property so it auto-updates when time changes
        // This timer just ensures we re-check even without a property change
        onTriggered: { var _ = root.dndActive }
    }
}
