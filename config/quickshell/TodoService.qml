pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// TodoService — day-keyed todo store, persisted to ~/.local/share/qs-todos.json
// Key format: "YYYY-MM-DD"  →  [ { id, text, done, pinned, created } ]
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

    function addTodo(text, dateStr) {
        var d = dateStr ?? root.today
        var list = (root.todos[d] ?? []).slice()
        list.push({
            id:      Date.now() + Math.random(),
            text:    text.trim(),
            done:    false,
            pinned:  false,
            created: new Date().toISOString()
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

    function clearDone(dateStr) {
        var copy = Object.assign({}, root.todos)
        copy[dateStr] = (copy[dateStr] ?? []).filter(t => !t.done)
        root.todos = copy
        root._save()
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
