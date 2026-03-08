import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// Full launcher — centered overlay
// Modes: apps | clip | emoji | calc | words
PanelWindow {
    id: root

    required property var barWindow

    // Center on screen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell:launcher"
    exclusiveZone: 0
    anchors {}   // no anchors = floats freely

    implicitWidth:  screen.width
    implicitHeight: screen.height
    color: "transparent"
    screen: barWindow ? barWindow.screen : undefined

    property string mode: LauncherService.mode
    property string query: ""
    property var    results: []
    property int    selectedIdx: 0
    property bool   calcResult: false

    // ── Mode switching ────────────────────────────────────────────────────────
    onModeChanged: {
        query = ""
        results = []
        selectedIdx = 0
        calcResult = false
        searchInput.forceActiveFocus()
        if (mode === "clip")   loadClip.running = true
        if (mode === "emoji")  loadEmoji.running = true
        if (mode === "words")  loadWords.running = true
        if (mode === "apps")   loadApps.running = true
    }

    onQueryChanged: {
        selectedIdx = 0
        if (mode === "calc" && query !== "") runCalc.running = true
        else if (mode === "calc") results = []
        else if (mode === "words") {
            // Re-run grep process with new query
            loadWords.running = false
            Qt.callLater(() => { loadWords.running = true })
        }
        else filterResults()
    }

    // ── Raw data stores ───────────────────────────────────────────────────────
    property var allApps:   []
    property var allClip:   []
    property var allEmoji:  []
    property var allWords:  []

    function filterResults() {
        var q = query.toLowerCase().trim()
        var src = mode === "apps"  ? allApps
                : mode === "clip"  ? allClip
                : mode === "emoji" ? allEmoji
                : mode === "words" ? allWords
                : []
        if (q === "") {
            results = src.slice(0, mode === "apps" ? src.length : 100)
        } else {
            results = src.filter(item => {
                var text = typeof item === "string" ? item : (item.name + " " + (item.keywords || ""))
                return text.toLowerCase().includes(q)
            }).slice(0, mode === "apps" ? 500 : 100)
        }
    }

    // ── Activate selected item ────────────────────────────────────────────────
    function activate(item) {
        if (mode === "apps") {
            // Record frecency
            Quickshell.execDetached([
                "python3", "-c",
                "import json, os\n" +
                "p = os.path.expanduser('~/.local/share/qs-launcher-frecency.json')\n" +
                "try: d = json.load(open(p))\n" +
                "except: d = {}\n" +
                "nm = " + JSON.stringify(item.name) + "\n" +
                "d[nm] = d.get(nm, 0) + 1\n" +
                "json.dump(d, open(p,'w'))"
            ])
            Quickshell.execDetached(["bash", "-c", item.exec])
        } else if (mode === "clip") {
            Quickshell.execDetached([
                "python3", "-c",
                "import subprocess\n" +
                "line = " + JSON.stringify(item) + "\n" +
                "r = subprocess.run(['cliphist','decode'], input=line.encode(), capture_output=True)\n" +
                "subprocess.run(['wl-copy'], input=r.stdout)"
            ])
        } else if (mode === "emoji") {
            Quickshell.execDetached(["bash", "-c",
                "printf '%s' " + JSON.stringify(item.char) + " | wl-copy"])
        } else if (mode === "calc") {
            Quickshell.execDetached(["bash", "-c",
                "printf '%s' " + JSON.stringify(item) + " | wl-copy && notify-send -t 2000 \"Copied\" " + JSON.stringify(item)])
        } else if (mode === "words") {
            Quickshell.execDetached(["bash", "-c",
                "printf '%s' " + JSON.stringify(item) + " | wl-copy"])
        }
        close()
    }

    function open() {
        mode = LauncherService.mode
        visible = true
        Qt.callLater(() => searchInput.forceActiveFocus())
    }

    function close() {
        visible = false
        query = ""
        LauncherService.open = false
    }

    // Self-managing — responds to LauncherService singleton
    Connections {
        target: LauncherService
        function onOpenChanged() {
            if (LauncherService.open) root.open()
            else if (root.visible) { root.visible = false; root.query = "" }
        }
        function onModeChanged() {
            if (root.visible) root.mode = LauncherService.mode
        }
    }
    onVisibleChanged: if (!visible) LauncherService.open = false

    // ── Processes ────────────────────────────────────────────────────────────

    // Apps — python3 resolves icons across all themes, sorts by frecency
    Process {
        id: loadApps
        command: [
            "python3", "-c",
            "import os, re, glob, json\n" +
            "\n" +
            "# Load frecency counts\n" +
            "fpath = os.path.expanduser('~/.local/share/qs-launcher-frecency.json')\n" +
            "try: frecency = json.load(open(fpath))\n" +
            "except: frecency = {}\n" +
            "\n" +
            "# Build icon lookup index once\n" +
            "icon_index = {}\n" +
            "icon_dirs = [\n" +
            "    '/usr/share/icons/hicolor/48x48/apps',\n" +
            "    '/usr/share/icons/hicolor/32x32/apps',\n" +
            "    '/usr/share/icons/hicolor/256x256/apps',\n" +
            "    '/usr/share/icons/hicolor/scalable/apps',\n" +
            "    '/usr/share/icons/Papirus/48x48/apps',\n" +
            "    '/usr/share/icons/breeze/apps/48',\n" +
            "    '/usr/share/pixmaps',\n" +
            "    os.path.expanduser('~/.local/share/icons'),\n" +
            "]\n" +
            "for d in icon_dirs:\n" +
            "    if not os.path.isdir(d): continue\n" +
            "    for f in os.listdir(d):\n" +
            "        stem = os.path.splitext(f)[0]\n" +
            "        if stem not in icon_index:\n" +
            "            icon_index[stem] = os.path.join(d, f)\n" +
            "\n" +
            "def find_icon(ic):\n" +
            "    if not ic: return ''\n" +
            "    if ic.startswith('/'): return ic if os.path.exists(ic) else ''\n" +
            "    return icon_index.get(ic, '')\n" +
            "\n" +
            "# Parse .desktop files\n" +
            "app_dirs = ['/usr/share/applications', '/usr/local/share/applications',\n" +
            "            os.path.expanduser('~/.local/share/applications')]\n" +
            "seen = set()\n" +
            "entries = []\n" +
            "for d in app_dirs:\n" +
            "    for path in sorted(glob.glob(d + '/*.desktop')):\n" +
            "        try:\n" +
            "            txt = open(path, errors='replace').read()\n" +
            "            if re.search(r'^NoDisplay=true', txt, re.M): continue\n" +
            "            def field(k): m=re.search(r'^'+k+'=(.+)',txt,re.M); return m.group(1).strip() if m else ''\n" +
            "            nm = field('Name')\n" +
            "            if not nm or nm in seen: continue\n" +
            "            seen.add(nm)\n" +
            "            ex = re.sub(r' ?%[uUfFdDnNickvm]', '', field('Exec')).strip()\n" +
            "            if not ex: continue\n" +
            "            ic = find_icon(field('Icon'))\n" +
            "            entries.append((nm, ex, ic, frecency.get(nm, 0)))\n" +
            "        except: pass\n" +
            "\n" +
            "# Sort: frecency desc, then alpha\n" +
            "entries.sort(key=lambda x: (-x[3], x[0].lower()))\n" +
            "for nm,ex,ic,_ in entries:\n" +
            "    print('ENTRY:' + nm + '|SEP|' + ex + '|SEP|' + ic)"
        ]
        running: false
        stdout: SplitParser {
            onRead: data => {
                if (!data.startsWith("ENTRY:")) return
                var parts = data.slice(6).split("|SEP|")
                if (parts.length >= 2 && parts[1].trim() !== "") {
                    var s = root.allApps.slice()
                    s.push({ name: parts[0].trim(), exec: parts[1].trim(), iconPath: (parts[2] || "").trim() })
                    root.allApps = s
                }
            }
        }
        onRunningChanged: {
            if (running) root.allApps = []
            else root.filterResults()
        }
    }

    // Clipboard
    Process {
        id: loadClip
        command: ["bash", "-c", "cliphist list 2>/dev/null | head -200"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                var s = root.allClip.slice()
                s.push(data)
                root.allClip = s
            }
        }
        onRunningChanged: {
            if (running) root.allClip = []
            else root.filterResults()
        }
    }

    // Emoji — python3 direct, no bash wrapper
    Process {
        id: loadEmoji
        command: [
            "python3", "-c",
            "import unicodedata\n" +
            "ranges = (list(range(0x1F600,0x1F650)) + list(range(0x1F300,0x1F600)) +\n" +
            "          list(range(0x1F900,0x1FA00)) + list(range(0x2600,0x27C0)) +\n" +
            "          list(range(0x1F1E0,0x1F200)))\n" +
            "seen = set()\n" +
            "for c in ranges:\n" +
            "    ch = chr(c)\n" +
            "    if ch in seen: continue\n" +
            "    if unicodedata.category(ch) in ('Cn','Cc'): continue\n" +
            "    seen.add(ch)\n" +
            "    print(ch + '\\t' + unicodedata.name(ch,'').lower())"
        ]
        running: false
        stdout: SplitParser {
            onRead: data => {
                var parts = data.split("\t")
                if (parts[0]) {
                    var s = root.allEmoji.slice()
                    s.push({ char: parts[0], keywords: parts[1] || "" })
                    root.allEmoji = s
                }
            }
        }
        onRunningChanged: {
            if (running) root.allEmoji = []
            else root.filterResults()
        }
    }
    // Words — python3 grep on demand, shell-agnostic
    Process {
        id: loadWords
        command: [
            "python3", "-c",
            "import sys, os\n" +
            "q = " + JSON.stringify(root.query.trim().toLowerCase()) + "\n" +
            "paths = [\n" +
            "    os.path.expanduser('~/.local/wordlists/wordnet-index.txt'),\n" +
            "    os.path.expanduser('~/wordlists/wordnet-index.txt'),\n" +
            "    os.path.expanduser('~/.wordlist'),\n" +
            "]\n" +
            "f = next((p for p in paths if os.path.exists(p)), None)\n" +
            "if not f: sys.exit(0)\n" +
            "count = 0\n" +
            "for line in open(f, errors='replace'):\n" +
            "    l = line.strip()\n" +
            "    if not l: continue\n" +
            "    if not q or q in l.lower():\n" +
            "        print(l)\n" +
            "        count += 1\n" +
            "        if count >= 150: break"
        ]
        running: false
        stdout: SplitParser {
            onRead: data => {
                if (!data.trim()) return
                var s = root.allWords.slice()
                s.push(data.trim())
                root.allWords = s
            }
        }
        onRunningChanged: {
            if (running) root.allWords = []
            else root.filterResults()
        }
    }

    // Calculator
    Process {
        id: runCalc
        command: [
            "python3", "-c",
            "import subprocess, sys, re\n" +
            "q = " + JSON.stringify(root.query.trim()) + "\n" +
            "if not q: sys.exit(0)\n" +
            "r = subprocess.run(['/usr/bin/qalc', '+u8', '-color=never', '-terse'],\n" +
            "    input=q, capture_output=True, text=True, timeout=3)\n" +
            "lines = [l.strip() for l in r.stdout.splitlines()\n" +
            "         if l.strip() and not l.strip().startswith('>')]\n" +
            "# Remove ANSI escapes\n" +
            "clean = [re.sub(r'\\x1b\\[[0-9;]*m', '', l) for l in lines]\n" +
            "result = clean[-1] if clean else ''\n" +
            "if result: print(result)"
        ]
        running: false
        stdout: SplitParser {
            onRead: data => {
                var r = data.trim()
                if (r) root.results = [r]
            }
        }
        onRunningChanged: if (running) root.results = []
    }

    // ── Keyboard handler ──────────────────────────────────────────────────────
    // Full-screen dim backdrop — captures keys and click-outside-to-close
    Rectangle {
        anchors.fill: parent
        color: "#aa000000"

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        // ── Launcher card ─────────────────────────────────────────────────────
        Rectangle {
            id: card
            anchors.centerIn: parent
            width:  700
            height: 520
            radius: 8
            color:  "#f00d1117"
            border.color: "#445bcefa"
            border.width: 1

            // Top glow line
            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 1
                color: "#660df0ff"
                radius: 1
            }

            MouseArea {
                anchors.fill: parent
                // Consume clicks so they don't fall through to backdrop close
                onClicked: {}
            }

            ColumnLayout {
                anchors { fill: parent; margins: 16 }
                spacing: 10

                // ── Mode tabs ─────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { id: "apps",  label: "\u{f0349}  Apps" },
                            { id: "clip",  label: "\u{f0179}  Clip" },
                            { id: "emoji", label: "\u{f0e02}  Emoji" },
                            { id: "calc",  label: "\u{f1065}  Calc" },
                            { id: "words", label: "\u{f02d}   Words" },
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: root.mode === modelData.id
                            height: 26
                            width: tabLabel.implicitWidth + 20
                            radius: 4
                            color:  active ? "#220df0ff" : "#110d1117"
                            border.color: active ? "#660df0ff" : "#22ffffff"
                            border.width: 1

                            Text {
                                id: tabLabel
                                anchors.centerIn: parent
                                text: modelData.label
                                color: active ? Theme.cyan : Theme.textDim
                                font.family: Theme.fontFamily
                                font.pointSize: 7
                                font.bold: active
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.mode = modelData.id
                            }

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Close button
                    Text {
                        text: "✕"
                        color: Theme.red
                        font.pointSize: 10
                        MouseArea { anchors.fill: parent; onClicked: root.close() }
                    }
                }

                // ── Search bar ────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 5
                    color: "#1a1e2e"
                    border.color: searchInput.activeFocus ? "#660df0ff" : "#33ffffff"
                    border.width: 1

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 8

                        Text {
                            text: root.mode === "apps"  ? "\u{f0349}"
                                : root.mode === "clip"  ? "\u{f0179}"
                                : root.mode === "emoji" ? "\u{f0e02}"
                                : root.mode === "calc"  ? "\u{f1065}"
                                : "\u{f02d}"
                            color: Theme.cyan
                            font.family: Theme.fontFamily
                            font.pointSize: 10
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pointSize: 10
                            selectionColor: "#330df0ff"
                            text: root.query
                            onTextChanged: root.query = text
                            focus: true

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    if (root.query !== "") root.query = ""
                                    else root.close()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (root.results.length > 0)
                                        root.activate(root.results[root.selectedIdx])
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Down) {
                                    root.selectedIdx = Math.min(root.selectedIdx + 1, root.results.length - 1)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Up) {
                                    root.selectedIdx = Math.max(root.selectedIdx - 1, 0)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Tab) {
                                    var modes = ["apps","clip","emoji","calc","words"]
                                    var i = modes.indexOf(root.mode)
                                    root.mode = modes[(i + 1) % modes.length]
                                    event.accepted = true
                                }
                            }
                        }

                        // Clear button
                        Text {
                            visible: root.query !== ""
                            text: "✕"
                            color: Theme.textDimmer
                            font.pointSize: 8
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.query = ""
                            }
                        }
                    }
                }

                // ── Results area — single unified ListView for all modes ──────
                ListView {
                    id: resultList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.results
                    spacing: 2
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    // Auto-scroll to keep selected item visible
                    onCountChanged: positionViewAtIndex(root.selectedIdx, ListView.Contain)

                    Connections {
                        target: root
                        function onSelectedIdxChanged() {
                            resultList.positionViewAtIndex(root.selectedIdx, ListView.Contain)
                        }
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width:  resultList.width
                        height: 40
                        radius: 5
                        color: root.selectedIdx === index ? "#220df0ff" : "#00000000"
                        border.color: root.selectedIdx === index ? "#440df0ff" : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 80 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 12 }
                            spacing: 10

                            // App icon
                            Image {
                                id: entryIcon
                                visible: root.mode === "apps" && (modelData.iconPath || "") !== ""
                                width: 24; height: 24
                                sourceSize: Qt.size(24, 24)
                                source: (root.mode === "apps" && modelData.iconPath)
                                    ? "file://" + modelData.iconPath : ""
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                            }

                            // Fallback initial for apps with no icon
                            Rectangle {
                                visible: root.mode === "apps" && entryIcon.status !== Image.Ready
                                width: 24; height: 24
                                radius: 5
                                color: {
                                    var h = (modelData.name ? modelData.name.charCodeAt(0) * 137 % 360 : 0) / 360
                                    return Qt.hsla(h, 0.55, 0.4, 0.5)
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                                    color: "white"
                                    font.pointSize: 9
                                    font.bold: true
                                }
                            }

                            // Emoji char
                            Text {
                                visible: root.mode === "emoji"
                                text: (root.mode === "emoji" && modelData.char) ? modelData.char : ""
                                font.pointSize: 16
                                color: "white"
                            }

                            // Main label
                            Text {
                                Layout.fillWidth: true
                                text: {
                                    if (root.mode === "apps")  return modelData.name || ""
                                    if (root.mode === "emoji") return modelData.keywords || ""
                                    if (typeof modelData === "string") return modelData
                                    return modelData.toString()
                                }
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pointSize: 8
                                elide: Text.ElideRight
                            }

                            // Calc copy hint
                            Text {
                                visible: root.mode === "calc"
                                text: "enter to copy"
                                color: Theme.textDimmer
                                font.family: Theme.fontFamily
                                font.pointSize: 6
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.selectedIdx = index
                            onClicked: root.activate(modelData)
                        }
                    }

                    // Empty state
                    Item {
                        anchors.centerIn: parent
                        visible: root.results.length === 0 && root.mode !== "calc"
                        Text {
                            anchors.centerIn: parent
                            text: root.mode === "apps"  ? "No apps found"
                                : root.mode === "clip"  ? "Clipboard is empty"
                                : root.mode === "emoji" ? "Loading emoji..."
                                : root.mode === "words" ? (root.query === "" ? "Type to search" : "No matches")
                                : ""
                            color: Theme.textDimmer
                            font.family: Theme.fontFamily
                            font.pointSize: 8
                        }
                    }
                }

                // ── Footer hint ───────────────────────────────────────────────
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "↑↓ / jk navigate  ·  enter select  ·  tab switch mode  ·  esc close"
                    color: Theme.textDimmer
                    font.family: Theme.fontFamily
                    font.pointSize: 6
                }
            }
        }
    }
}
