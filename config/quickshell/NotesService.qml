pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// NotesService — plain-text note store in a user-controlled directory.
// One file per note (extension from SettingsService.notesExtension, default
// .md). A pinned "Scratchpad" note always sits at the top for instant brain
// dumping. Pins live in a `.pinned.json` sidecar inside the notes dir; the
// last opened note is remembered in `.qs-state.json` (same dir).
//
// Autosave policy (mirrors Noctalia's notes plugin):
//   - ~1.8s after the last keystroke (setContent restarts the debounce timer)
//   - on navigating to another note (openNote flushes the current buffer first)
//   - on panel close
//   - Ctrl+Enter saves immediately (see NotesPanel)
Scope {
    id: root

    property string notesDir: "~/Documents/Notes"
    readonly property string scratchName: "Scratchpad"

    property bool open: false
    property bool loaded: false
    property var  notes: []          // [{ name, pinned }]
    property var  pins: ({})         // name -> true
    property string last: ""         // last opened note name

    property string currentName: ""
    property string currentContent: ""
    property string savedContent: ""
    property bool   saving: false

    property string _pendingOpen: ""   // open this note after the current write lands
    property bool   _pendingCreate: false       // pending open is a "create" (uses _pendingCreateContent)
    property string _pendingCreateContent: ""   // content for the pending create
    property bool   _refreshAfterWrite: false   // rebuild the note list once the write lands

    readonly property string glyph: "\u{f0f6}"

    function toggle() { root.open = !root.open }
    function show()   { root.open = true }
    function hide()   { root.open = false }

    function filePath(name) { return root.notesDir + "/" + name + "." + SettingsService.notesExtension }
    function isPinned(name) { return !!root.pins[name] }

    function noteExists(name) {
        for (var i = 0; i < root.notes.length; i++)
            if (root.notes[i].name === name) return true
        return false
    }

    // Strip path separators + leading dots; fall back to a timestamp name.
    function sanitize(name) {
        var s = String(name).replace(/[\/\\]/g, "-").replace(/^\.+/, "").trim()
        if (s === "") return root.timestampName()
        return s
    }

    function timestampName() { return Qt.formatDateTime(new Date(), "yyyy-MM-dd HHmm") }

    // ── Listing / load ─────────────────────────────────────────────────────

    function refresh() {
        refreshProc.command = [
            "python3", "-c",
            "import os, json, sys\n" +
            "d = os.path.expanduser(sys.argv[1])\n" +
            "os.makedirs(d, exist_ok=True)\n" +
            "ext = sys.argv[2]\n" +
            "names = sorted(f[:-len(ext)] for f in os.listdir(d)\n" +
            "             if f.endswith(ext) and not f.startswith('.'))\n" +
            "pins = {}\n" +
            "try:\n" +
            "    pins = json.load(open(os.path.join(d, '.pinned.json')))\n" +
            "except Exception:\n" +
            "    pass\n" +
            "state = {}\n" +
            "try:\n" +
            "    state = json.load(open(os.path.join(d, '.qs-state.json')))\n" +
            "except Exception:\n" +
            "    pass\n" +
            "print(json.dumps({'names': names, 'pins': pins, 'last': state.get('last', ''), 'ext': ext}))",
            root.notesDir, "." + SettingsService.notesExtension
        ]
        refreshProc.running = true
    }

    Process {
        id: refreshProc
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var o = JSON.parse(data.trim())
                    var list = []
                    var names = o.names || []
                    for (var i = 0; i < names.length; i++) {
                        list.push({ name: names[i], pinned: !!(o.pins && o.pins[names[i]]) })
                    }
                    root.notes = list
                    root.pins = o.pins || {}
                    root.last = o.last || ""
                    root.loaded = true
                    // A created note is opened once its file lands.
                    if (root._pendingOpen !== "" && root.noteExists(root._pendingOpen)) {
                        var n = root._pendingOpen
                        root._pendingOpen = ""
                        root._load(n)
                    }
                } catch (e) {
                    console.log("Notes refresh error: " + e)
                }
            }
        }
    }

    // ── Note lifecycle ─────────────────────────────────────────────────────

    function openNote(name) {
        if (root.currentContent !== root.savedContent && root.currentName !== "") {
            root._pendingOpen = name
            root.saveCurrent()
            return
        }
        root._load(name)
    }

    function openScratchpad() { root.openNote(root.scratchName) }

    function _load(name) {
        root.currentName = name
        root.currentContent = ""
        root.savedContent = ""
        root.saving = false
        readProc.command = [
            "python3", "-c",
            "import os, sys\n" +
            "try:\n" +
            "    sys.stdout.write(open(os.path.expanduser(sys.argv[1])).read())\n" +
            "except Exception:\n" +
            "    pass",
            root.filePath(name)
        ]
        readProc.running = true
        root._saveState()
    }

    Process {
        id: readProc
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.currentContent = data
                root.savedContent = data
                root.saving = false
            }
        }
    }

    function createNote(name, content) {
        var n = root.sanitize(name)
        if (root.noteExists(n)) n = n + "-" + Math.floor(Date.now() / 1000) % 100000
        // If the current note has unsaved edits, flush it first, then create.
        if (root.currentContent !== root.savedContent && root.currentName !== "") {
            root._pendingOpen = n
            root._pendingCreate = true
            root._pendingCreateContent = content || ""
            root.saveCurrent()
            return
        }
        root._doCreate(n, content || "")
    }

    function _doCreate(n, content) {
        fsWriteProc.command = [
            "python3", "-c",
            "import os, sys\n" +
            "p = os.path.expanduser(sys.argv[1])\n" +
            "os.makedirs(os.path.dirname(p), exist_ok=True)\n" +
            "open(p, 'w').write(sys.argv[2])",
            root.filePath(n), content
        ]
        fsWriteProc.running = true
        // Switch the editor to the new note immediately so the panel doesn't
        // fall back to "last opened" before the file lands.
        root.currentName = n
        root.currentContent = content
        root.savedContent = content
        root.refresh()
    }

    function renameNote(oldName, newName) {
        var n = root.sanitize(newName)
        if (n === "" || n === oldName) return
        if (root.noteExists(n)) { root.currentName = oldName; return }
        // Write current buffer to the new path and drop the old file — this
        // flushes unsaved edits and renames in one step.
        fsWriteProc.command = [
            "python3", "-c",
            "import os, sys\n" +
            "old = os.path.expanduser(sys.argv[1]); new = os.path.expanduser(sys.argv[2])\n" +
            "os.makedirs(os.path.dirname(new), exist_ok=True)\n" +
            "open(new, 'w').write(sys.argv[3])\n" +
            "try: os.remove(old)\n" +
            "except OSError: pass",
            root.filePath(oldName), root.filePath(n), root.currentContent
        ]
        fsWriteProc.running = true
        root.savedContent = root.currentContent
        root.currentName = n
        if (root.pins[oldName]) {
            var p = Object.assign({}, root.pins)
            delete p[oldName]
            p[n] = true
            root.pins = p
            root._writePins()
        }
        root._saveState()
        root._refreshAfterWrite = true
    }

    function deleteCurrent() {
        if (root.currentName === "") return
        fsWriteProc.command = [
            "python3", "-c",
            "import os, sys\n" +
            "os.remove(os.path.expanduser(sys.argv[1]))",
            root.filePath(root.currentName)
        ]
        fsWriteProc.running = true
        if (root.pins[root.currentName]) {
            var p = Object.assign({}, root.pins)
            delete p[root.currentName]
            root.pins = p
            root._writePins()
        }
        root.currentName = ""
        root.currentContent = ""
        root.savedContent = ""
        root._refreshAfterWrite = true
        root.openScratchpad()
    }

    function togglePinCurrent() {
        if (root.currentName === "") return
        var p = Object.assign({}, root.pins)
        if (p[root.currentName]) delete p[root.currentName]
        else p[root.currentName] = true
        root.pins = p
        root._writePins()
        root.refresh()
    }

    function appendScratchpad(text) {
        if (!text) return
        fsWriteProc.command = [
            "python3", "-c",
            "import os, sys\n" +
            "p = os.path.expanduser(sys.argv[1])\n" +
            "os.makedirs(os.path.dirname(p), exist_ok=True)\n" +
            "open(p, 'a').write(sys.argv[2] + '\\n')",
            root.filePath(root.scratchName), text
        ]
        fsWriteProc.running = true
    }

    function newNoteFromClipboard() {
        clipProc.running = true
    }

    Process {
        id: clipProc
        command: ["bash", "-c", "wl-paste 2>/dev/null || true"]
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var text = data.trim()
                root.createNote(root.timestampName(), text)
            }
        }
    }

    // ── Editing / autosave ─────────────────────────────────────────────────

    function setContent(text) {
        root.currentContent = text
        if (text !== root.savedContent && root.currentName !== "")
            autosaveTimer.restart()
    }

    function saveCurrent() {
        if (root.currentName === "" || root.saving) return
        root.savedContent = root.currentContent
        root.saving = true
        fsWriteProc.command = [
            "python3", "-c",
            "import os, sys\n" +
            "p = os.path.expanduser(sys.argv[1])\n" +
            "os.makedirs(os.path.dirname(p), exist_ok=True)\n" +
            "open(p, 'w').write(sys.argv[2])",
            root.filePath(root.currentName), root.currentContent
        ]
        fsWriteProc.running = true
    }

    Timer {
        id: autosaveTimer
        interval: 1800
        repeat: false
        onTriggered: root.saveCurrent()
    }

    Process {
        id: fsWriteProc
        running: false
        onExited: {
            root.saving = false
            if (root._pendingOpen !== "") {
                var n = root._pendingOpen
                root._pendingOpen = ""
                if (root._pendingCreate) {
                    root._pendingCreate = false
                    root._doCreate(n, root._pendingCreateContent)
                } else {
                    root._load(n)
                }
            }
            if (root._refreshAfterWrite) {
                root._refreshAfterWrite = false
                root.refresh()
            }
        }
    }

    // ── Sidecars (separate process — never touches fsWriteProc) ────────────

    function _writePins() {
        sidecarProc.command = [
            "python3", "-c",
            "import os, json, sys\n" +
            "d = os.path.expanduser(sys.argv[1])\n" +
            "os.makedirs(d, exist_ok=True)\n" +
            "json.dump(json.loads(sys.argv[2]), open(os.path.join(d, '.pinned.json'), 'w'))",
            root.notesDir, JSON.stringify(root.pins)
        ]
        sidecarProc.running = true
    }

    function _saveState() {
        if (root.currentName === "") return
        sidecarProc.command = [
            "python3", "-c",
            "import os, json, sys\n" +
            "d = os.path.expanduser(sys.argv[1])\n" +
            "os.makedirs(d, exist_ok=True)\n" +
            "json.dump({'last': sys.argv[2]}, open(os.path.join(d, '.qs-state.json'), 'w'))",
            root.notesDir, root.currentName
        ]
        sidecarProc.running = true
    }

    Process {
        id: sidecarProc
        running: false
    }

    Component.onCompleted: root.refresh()
}
