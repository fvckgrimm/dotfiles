pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// TodoService — day-keyed todo store, persisted to ~/.local/share/qs-todos.json
// Key format: "YYYY-MM-DD"  →  [ { id, text, done, pinned, created, time, remind } ]
// time: "HH:MM" format (24h), remind: minutes before (default 5)
Scope {
    id: root

    property bool  open:  false
    property var   todos: ({})          // all days, keyed by date string
    property string today: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property bool  _loaded: false

    // Public: todos for a given day (defaults to today)
    function dayTodos(dateStr) {
        return root.todos[dateStr] ?? []
    }

    // Public: count of incomplete todos today
    readonly property int pendingToday: {
        var list = root.todos[today] ?? []
        return list.filter(t => !t.done).length
    }

    function toggle() { root.open = !root.open }

    // ── CRUD ─────────────────────────────────────────────────────────────────

    function addTodo(text, dateStr, time, remind) {
        var d = dateStr ?? root.today
        var list = (root.todos[d] ?? []).slice()
        list.push({
            id:      Date.now() + Math.random(),
            text:    text.trim(),
            done:    false,
            pinned:  false,
            created: new Date().toISOString(),
            time:    time ?? "",
            remind:  remind !== undefined ? remind : 5
        })
        var copy = Object.assign({}, root.todos)
        copy[d] = list
        root.todos = copy
        root._save()
    }

    function setDone(dateStr, id, val) {
        var copy = Object.assign({}, root.todos)
        copy[dateStr] = (copy[dateStr] ?? []).map(t =>
            t.id === id ? Object.assign({}, t, { done: val }) : t
        )
        root.todos = copy
        root._save()
    }

    function togglePin(dateStr, id) {
        var copy = Object.assign({}, root.todos)
        copy[dateStr] = (copy[dateStr] ?? []).map(t =>
            t.id === id ? Object.assign({}, t, { pinned: !t.pinned }) : t
        )
        root.todos = copy
        root._save()
    }

    function removeTodo(dateStr, id) {
        var copy = Object.assign({}, root.todos)
        copy[dateStr] = (copy[dateStr] ?? []).filter(t => t.id !== id)
        root.todos = copy
        root._save()
    }

    function editTodo(dateStr, id, newText) {
        var copy = Object.assign({}, root.todos)
        copy[dateStr] = (copy[dateStr] ?? []).map(t =>
            t.id === id ? Object.assign({}, t, { text: newText }) : t
        )
        root.todos = copy
        root._save()
    }

    function setTime(dateStr, id, time) {
        var copy = Object.assign({}, root.todos)
        copy[dateStr] = (copy[dateStr] ?? []).map(t =>
            t.id === id ? Object.assign({}, t, { time: time }) : t
        )
        root.todos = copy
        root._save()
    }

    function setRemind(dateStr, id, minutes) {
        var copy = Object.assign({}, root.todos)
        copy[dateStr] = (copy[dateStr] ?? []).map(t =>
            t.id === id ? Object.assign({}, t, { remind: minutes }) : t
        )
        root.todos = copy
        root._save()
    }

    // Set time + reminder in one call ("" clears the time)
    function setSchedule(dateStr, id, time, remind) {
        var copy = Object.assign({}, root.todos)
        copy[dateStr] = (copy[dateStr] ?? []).map(t =>
            t.id === id
                ? Object.assign({}, t, { time: time ?? "", remind: remind !== undefined ? remind : 5 })
                : t
        )
        root.todos = copy
        root._save()
    }

    function clearDone(dateStr) {
        var copy = Object.assign({}, root.todos)
        copy[dateStr] = (copy[dateStr] ?? []).filter(t => !t.done)
        root.todos = copy
        root._save()
    }

    // ── Reminder checking ─────────────────────────────────────────────────────
    // Fires when the current minute hits the remind trigger (todo time minus X
    // minutes) or the due time itself. Uses a +5min catch-up window so reminders
    // still fire if quickshell was suspended/just started and a check was missed.
    function _checkReminders() {
        var now = new Date()
        var todayStr = Qt.formatDate(now, "yyyy-MM-dd")
        var currentMinutes = now.getHours() * 60 + now.getMinutes()

        var allTodos = root.todos[todayStr] ?? []
        for (var i = 0; i < allTodos.length; i++) {
            var t = allTodos[i]
            if (t.done || !t.time) continue

            var timeParts = t.time.split(":")
            if (timeParts.length !== 2) continue

            var todoMinutes = parseInt(timeParts[0]) * 60 + parseInt(timeParts[1])
            var remindMinutes = t.remind ?? 5
            var remindTrigger = todoMinutes - remindMinutes

            // Reminder "X min before"
            if (remindMinutes > 0
                && currentMinutes >= remindTrigger
                && currentMinutes - remindTrigger <= 5) {
                var rid = "todo-remind-" + t.id + "-" + todayStr
                if (!root._triggeredReminders.includes(rid)) {
                    root._triggeredReminders.push(rid)
                    NotificationService.send({
                        appName: "Todo",
                        summary: "Reminder: " + t.text,
                        body: "Due at " + t.time + "  ·  " + (currentMinutes - remindTrigger) + " min to go",
                        urgency: 1,
                        icon: "󰄲"
                    })
                }
            }

            // Due now
            if (currentMinutes >= todoMinutes && currentMinutes - todoMinutes <= 5) {
                var did = "todo-due-" + t.id + "-" + todayStr
                if (!root._triggeredReminders.includes(did)) {
                    root._triggeredReminders.push(did)
                    NotificationService.send({
                        appName: "Todo",
                        summary: "Due now: " + t.text,
                        body: "Scheduled for " + t.time,
                        urgency: 2,
                        icon: "󰄲"
                    })
                }
            }
        }

        // Clean up old triggered reminders (simple cap)
        if (root._triggeredReminders.length > 100) {
            root._triggeredReminders = root._triggeredReminders.slice(-100)
        }
    }

    property var _triggeredReminders: []

    // Check reminders every minute
    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root._checkReminders()
    }

    // Initial catch-up shortly after load (todos may already be loaded)
    Timer {
        interval: 5000
        running: true
        onTriggered: root._checkReminders()
    }

    // ── Persistence ───────────────────────────────────────────────────────────

    function _save() {
        saveProc.running = false
        var json = JSON.stringify(root.todos)
        saveProc.command = [
            "bash", "-c",
            "mkdir -p ~/.local/share && printf '%s' " +
            JSON.stringify(json).replace(/'/g, "'\\''") +
            " > ~/.local/share/qs-todos.json"
        ]
        saveProc.running = true
    }

    Process {
        id: saveProc
        running: false
    }

    Process {
        id: loadProc
        command: ["bash", "-c", "cat ~/.local/share/qs-todos.json 2>/dev/null || echo '{}'"]
        running: true
        stdout: SplitParser {
            splitMarker: ""   // read whole stdout at once
            onRead: data => {
                try {
                    root.todos = JSON.parse(data.trim())
                } catch(e) {
                    root.todos = {}
                }
                root._loaded = true
            }
        }
    }

    // Refresh "today" key at midnight
    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.today = Qt.formatDate(new Date(), "yyyy-MM-dd")
    }
}
