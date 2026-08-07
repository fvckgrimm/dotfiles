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
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell:launcher"
    exclusiveZone: 0
    anchors {}

    implicitWidth:  screen.width
    implicitHeight: screen.height
    color: "transparent"
    screen: barWindow ? barWindow.screen : undefined

    property string mode: LauncherService.mode
    property string query: ""
    property var    results: []
    property int    selectedIdx: 0
    property bool   calcResult: false
    property string clipFilter: "all"  // all | text | image | link

    onModeChanged: {
        query = ""
        results = []
        selectedIdx = 0
        clipFilter = "all"
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
        else if (mode === "words") { loadWords.running = false; Qt.callLater(() => { loadWords.running = true }) }
        else filterResults()
    }

    property var allApps:   []
    property var allClip:   []
    property var allEmoji:  []
    property var allWords:  []

    function filterResults() {
        var q = query.toLowerCase().trim()
        var src = mode === "apps"  ? allApps
                : mode === "clip"  ? (clipFilter === "all" ? allClip : allClip.filter(it => it.kind === clipFilter))
                : mode === "emoji" ? allEmoji
                : mode === "words" ? allWords
                : []
        if (q === "") {
            results = src.slice(0, mode === "apps" ? src.length : 100)
        } else {
            results = src.filter(item => {
                var text = typeof item === "string" ? item
                    : mode === "clip" ? (item.text || "")
                    : (item.name + " " + (item.keywords || ""))
                return text.toLowerCase().includes(q)
            }).slice(0, mode === "apps" ? 500 : 100)
        }
    }

    function activate(item) {
        if (mode === "apps") {
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
            if (item.kind === "image") {
                // Re-decode the original bytes and copy with the right mime.
                Quickshell.execDetached(["bash", "-c",
                    "printf '%s' " + JSON.stringify(item.line) + " | cliphist decode | wl-copy -t " + item.mime])
            } else {
                Quickshell.execDetached(["bash", "-c",
                    "printf '%s' " + JSON.stringify(item.text || item.line) + " | wl-copy"])
            }
        } else if (mode === "emoji") {
            Quickshell.execDetached(["bash", "-c", "printf '%s' " + JSON.stringify(item.char) + " | wl-copy"])
        } else if (mode === "calc") {
            Quickshell.execDetached(["bash", "-c",
                "printf '%s' " + JSON.stringify(item) + " | wl-copy && notify-send -t 2000 \"Copied\" " + JSON.stringify(item)])
        } else if (mode === "words") {
            Quickshell.execDetached(["bash", "-c", "printf '%s' " + JSON.stringify(item) + " | wl-copy"])
        }
        close()
    }

    // Delete a single clipboard-history entry without closing the launcher.
    // cliphist stores entries keyed by the "line" shown in `cliphist list`
    // (id<TAB>preview); `cliphist delete` takes that same line on stdin.
    function deleteClip(item) {
        Quickshell.execDetached([
            "bash", "-c",
            "printf '%s' " + JSON.stringify(item.line) + " | cliphist delete"
        ])
        root.allClip = root.allClip.filter(c => c.line !== item.line)
        root.filterResults()
        if (root.selectedIdx >= root.results.length) {
            root.selectedIdx = Math.max(0, root.results.length - 1)
        }
    }

    function open() {
        mode = LauncherService.mode
        visible = true
        Qt.callLater(() => searchInput.forceActiveFocus())
    }
    function close() { visible = false; query = ""; LauncherService.open = false }

    property bool _ready: false
    Component.onCompleted: Qt.callLater(() => { _ready = true })

    Connections {
        target: LauncherService
        function onOpenChanged() {
            if (!root._ready) return
            if (LauncherService.open) root.open()
            else if (root.visible) { root.visible = false; root.query = "" }
        }
        function onModeChanged() {
            if (!root._ready) return
            if (root.visible) root.mode = LauncherService.mode
        }
    }
    onVisibleChanged: if (_ready && !visible) LauncherService.open = false

    // ── Processes ────────────────────────────────────────────────────────
    Process {
        id: loadApps
        command: [
            "python3", "-c",
            "import os, re, glob, json\n" +
            "fpath = os.path.expanduser('~/.local/share/qs-launcher-frecency.json')\n" +
            "try: frecency = json.load(open(fpath))\n" +
            "except: frecency = {}\n" +
            "icon_index = {}\n" +
            "icon_dirs = [\n" +
            "    '/usr/share/icons/hicolor/48x48/apps',\n" +
            "    '/usr/share/icons/hicolor/32x32/apps',\n" +
            "    '/usr/share/icons/hicolor/256x256/apps',\n" +
            "    '/usr/share/icons/hicolor/scalable/apps',\n" +
            "    '/usr/share/icons/Papirus/48x48/apps',\n" +
            "    '/usr/share/icons/breeze/apps/48',\n" +
            "    os.path.expanduser('~/.nix-profile/share/icons/hicolor/32x32/apps'),\n" +
            "    os.path.expanduser('~/.nix-profile/share/icons/hicolor/scalable/apps'),\n" +
            "    '/usr/share/pixmaps',\n" +
            "    os.path.expanduser('~/.local/share/icons'),\n" +
            "]\n" +
            "for d in icon_dirs:\n" +
            "    if not os.path.isdir(d): continue\n" +
            "    for f in os.listdir(d):\n" +
            "        stem = os.path.splitext(f)[0]\n" +
            "        if stem not in icon_index:\n" +
            "            icon_index[stem] = os.path.join(d, f)\n" +
            "def find_icon(ic):\n" +
            "    if not ic: return ''\n" +
            "    if ic.startswith('/'): return ic if os.path.exists(ic) else ''\n" +
            "    return icon_index.get(ic, '')\n" +
            "app_dirs = ['/usr/share/applications', '/usr/local/share/applications',\n" +
            "            os.path.expanduser('~/.local/share/applications'),\n" +
            "            os.path.expanduser('~/.nix-profile/share/applications'),]\n" +
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
        onRunningChanged: { if (running) root.allApps = []; else root.filterResults() }
    }

    // Load clipboard history with type classification (text/image/link).
    // Each decoded entry is tagged; `text` holds the FULL content for copying
    // while `preview` is a shortened display string. Images get a downscaled
    // base64 PNG thumbnail for the list + preview pane. Output is one JSON
    // object per line (JSONL) — SplitParser's default "\n" marker delivers
    // complete lines regardless of how stdout is chunked, unlike a single
    // giant blob.
    Process {
        id: loadClip
        command: [
            "python3", "-c",
            "import json, subprocess, sys, io, base64\n" +
            "from PIL import Image\n" +
            "lines = subprocess.run(['cliphist','list'], capture_output=True).stdout.decode('utf-8','replace').splitlines()\n" +
            "count = 0\n" +
            "for line in lines:\n" +
            "    if not line.strip() or count >= 100: continue\n" +
            "    try:\n" +
            "        raw = subprocess.run(['cliphist','decode'], input=line.encode('utf-8','replace'), capture_output=True, timeout=5).stdout\n" +
            "    except Exception:\n" +
            "        continue\n" +
            "    if not raw: continue\n" +
            "    kind = 'text'; mime = 'text/plain'; text = ''; img = ''\n" +
            "    if raw[:8] == b'\\x89PNG\\r\\n\\x1a\\n':\n" +
            "        kind = 'image'; mime = 'image/png'\n" +
            "    elif raw[:2] == b'\\xff\\xd8':\n" +
            "        kind = 'image'; mime = 'image/jpeg'\n" +
            "    elif raw[:4] == b'RIFF' and raw[8:12] == b'WEBP':\n" +
            "        kind = 'image'; mime = 'image/webp'\n" +
            "    elif raw[:2] == b'BM':\n" +
            "        kind = 'image'; mime = 'image/bmp'\n" +
            "    if kind == 'image':\n" +
            "        try:\n" +
            "            im = Image.open(io.BytesIO(raw)).convert('RGBA')\n" +
            "            im.thumbnail((256,256))\n" +
            "            buf = io.BytesIO()\n" +
            "            im.save(buf, 'PNG')\n" +
            "            img = base64.b64encode(buf.getvalue()).decode()\n" +
            "        except Exception:\n" +
            "            img = ''\n" +
            "    else:\n" +
            "        text = raw.decode('utf-8', 'replace')\n" +
            "        if text.strip().startswith(('http://','https://','file://','mailto:','ssh://','ftp://')):\n" +
            "            kind = 'link'\n" +
            "        if not text.strip(): continue\n" +
            "    preview = ' '.join(text.split())[:160]\n" +
            "    sys.stdout.write(json.dumps({'line': line, 'kind': kind, 'mime': mime, 'text': text, 'preview': preview, 'img': img}) + '\\n')\n" +
            "    count += 1"
        ]
        running: false
        stdout: SplitParser {
            onRead: data => {
                var d = data.trim()
                if (!d) return
                try {
                    var e = JSON.parse(d)
                    var s = root.allClip.slice()
                    s.push(e)
                    root.allClip = s
                } catch (err) {
                    console.log("Error parsing clip line: " + d.slice(0, 60))
                }
            }
        }
        onRunningChanged: { if (running) root.allClip = []; else root.filterResults() }
    }

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
                if (parts[0]) { var s = root.allEmoji.slice(); s.push({ char: parts[0], keywords: parts[1] || "" }); root.allEmoji = s }
            }
        }
        onRunningChanged: { if (running) root.allEmoji = []; else root.filterResults() }
    }

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
            onRead: data => { if (!data.trim()) return; var s = root.allWords.slice(); s.push(data.trim()); root.allWords = s }
        }
        onRunningChanged: { if (running) root.allWords = []; else root.filterResults() }
    }

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
            "clean = [re.sub(r'\\x1b\\[[0-9;]*m', '', l) for l in lines]\n" +
            "result = clean[-1] if clean else ''\n" +
            "if result: print(result)"
        ]
        running: false
        stdout: SplitParser {
            onRead: data => { var r = data.trim(); if (r) root.results = [r] }
        }
        onRunningChanged: if (running) root.results = []
    }

    // ── Keyboard handler / backdrop ──────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Theme.withAlpha("#000000", 0.6)

        MouseArea { anchors.fill: parent; onClicked: root.close() }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width:  root.mode === "clip" ? 960 : 700
            height: 520
            radius: Theme.radiusXl
            color:  Theme.cardColor()
            border.color: Theme.cardBorder()
            border.width: 1
            Behavior on width { NumberAnimation { duration: Theme.motionMedium; easing: Theme.easingStandard } }

            MouseArea { anchors.fill: parent; onClicked: {} }

            ColumnLayout {
                anchors { fill: parent; margins: Theme.spacingXl }
                spacing: Theme.spacingMd

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSm

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
                            height: 28
                            width: tabLabel.implicitWidth + Theme.spacingLg
                            radius: Theme.radiusMd
                            color: active ? Theme.withAlpha(Theme.primary, 0.16) : "transparent"

                            Text {
                                id: tabLabel
                                anchors.centerIn: parent
                                text: modelData.label
                                color: active ? Theme.primary : Theme.surfaceTextVariant
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.labelLarge
                                font.bold: active
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.mode = modelData.id }
                            Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "✕"
                        color: Theme.surfaceTextVariant
                        font.pointSize: Theme.titleMedium
                        MouseArea { anchors.fill: parent; onClicked: root.close() }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: Theme.radiusMd
                    color: Theme.surfaceContainerLow
                    clip: true
                    border.color: searchInput.activeFocus ? Theme.withAlpha(Theme.primary, 0.5) : "transparent"
                    border.width: 1

                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.spacingMd; rightMargin: Theme.spacingMd }
                        spacing: Theme.spacingSm

                        Text {
                            text: root.mode === "apps"  ? "\u{f0349}"
                                : root.mode === "clip"  ? "\u{f0179}"
                                : root.mode === "emoji" ? "\u{f0e02}"
                                : root.mode === "calc"  ? "\u{f1065}"
                                : "\u{f02d}"
                            color: Theme.primary
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.titleSmall
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: Theme.surfaceText
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.bodyLarge
                            selectionColor: Theme.withAlpha(Theme.primary, 0.2)
                            text: root.query
                            onTextChanged: root.query = text
                            focus: true

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    if (root.query !== "") root.query = ""
                                    else root.close()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (root.results.length > 0) root.activate(root.results[root.selectedIdx])
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Down) {
                                    root.selectedIdx = Math.min(root.selectedIdx + 1, root.results.length - 1)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Up) {
                                    root.selectedIdx = Math.max(root.selectedIdx - 1, 0)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Delete && root.mode === "clip" && root.results.length > 0) {
                                    root.deleteClip(root.results[root.selectedIdx])
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Tab) {
                                    var modes = ["apps","clip","emoji","calc","words"]
                                    var i = modes.indexOf(root.mode)
                                    root.mode = modes[(i + 1) % modes.length]
                                    event.accepted = true
                                }
                            }
                        }

                        Text {
                            visible: root.query !== ""
                            text: "✕"
                            color: Theme.surfaceTextDim
                            font.pointSize: Theme.labelLarge
                            MouseArea { anchors.fill: parent; onClicked: root.query = "" }
                        }
                    }
                }

                // Clipboard type filter (clip mode only)
                RowLayout {
                    Layout.fillWidth: true
                    visible: root.mode === "clip"
                    spacing: Theme.spacingSm

                    Repeater {
                        model: [
                            { id: "all",   label: "All" },
                            { id: "text",  label: "Text" },
                            { id: "image", label: "Images" },
                            { id: "link",  label: "Links" },
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: root.clipFilter === modelData.id
                            height: 24
                            width: chipLabel.implicitWidth + Theme.spacingLg
                            radius: Theme.radiusMd
                            color: active ? Theme.withAlpha(Theme.primary, 0.16)
                                : (chipMa.containsMouse ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : "transparent")
                            Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                            Text {
                                id: chipLabel
                                anchors.centerIn: parent
                                text: modelData.label
                                color: active ? Theme.primary : Theme.surfaceTextVariant
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.labelLarge
                                font.bold: active
                            }
                            MouseArea {
                                id: chipMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.clipFilter = modelData.id
                                    root.selectedIdx = 0
                                    root.filterResults()
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.allClip.length + " items"
                        color: Theme.surfaceTextDim
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.labelSmall
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.spacingMd

                ListView {
                    id: resultList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.results
                    spacing: Theme.spacingXs
                    rightMargin: 16
                    ScrollBar.vertical: ScrollBar {
                        id: resultScrollbar
                        policy: ScrollBar.AsNeeded
                        parent: resultList
                        anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
                    }

                    onCountChanged: positionViewAtIndex(root.selectedIdx, ListView.Contain)
                    Connections {
                        target: root
                        function onSelectedIdxChanged() { resultList.positionViewAtIndex(root.selectedIdx, ListView.Contain) }
                    }

                    delegate: Rectangle {
                        id: resultDelegate
                        required property var modelData
                        required property int index
                        width:  resultList.width - resultList.rightMargin
                        height: 40
                        radius: Theme.radiusMd
                        clip: true
                        color: root.selectedIdx === index ? Theme.withAlpha(Theme.primary, 0.14) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: Theme.spacingMd; rightMargin: Theme.spacingSm }
                            spacing: Theme.spacingMd

                            Image {
                                id: entryIcon
                                visible: root.mode === "apps" && (modelData.iconPath || "") !== ""
                                width: 24; height: 24
                                sourceSize: Qt.size(24, 24)
                                source: (root.mode === "apps" && modelData.iconPath) ? "file://" + modelData.iconPath : ""
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                            }

                            Rectangle {
                                visible: root.mode === "apps" && entryIcon.status !== Image.Ready
                                width: 24; height: 24
                                radius: Theme.radiusSm
                                color: {
                                    var h = (modelData.name ? modelData.name.charCodeAt(0) * 137 % 360 : 0) / 360
                                    return Qt.hsla(h, 0.45, 0.35, 0.6)
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                                    color: "white"; font.pointSize: Theme.labelLarge; font.bold: true
                                }
                            }

                            Text {
                                visible: root.mode === "emoji"
                                text: (root.mode === "emoji" && modelData.char) ? modelData.char : ""
                                font.pointSize: Theme.titleLarge
                                color: Theme.surfaceText
                            }

                            Image {
                                visible: root.mode === "clip" && modelData.kind === "image" && !!modelData.img
                                width: 28; height: 28
                                sourceSize: Qt.size(28, 28)
                                source: modelData.img ? "data:image/png;base64," + modelData.img : ""
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: {
                                    if (root.mode === "apps")  return modelData.name || ""
                                    if (root.mode === "emoji") return modelData.keywords || ""
                                    if (root.mode === "clip")  return (modelData.kind === "image")
                                        ? (modelData.mime || "image") + "  " + (modelData.line.split("\t")[0] || "")
                                        : modelData.preview
                                    if (typeof modelData === "string") return modelData
                                    return modelData.toString()
                                }
                                color: Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.labelLarge
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }

                            Text {
                                visible: root.mode === "clip" && modelData.kind !== "image"
                                text: modelData.kind === "link" ? "link" : (modelData.text || "").length + " ch"
                                color: Theme.surfaceTextDim
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.labelSmall
                            }

                            Text {
                                visible: root.mode === "calc"
                                text: "enter to copy"
                                color: Theme.surfaceTextDim
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.labelSmall
                            }

                            // Per-item clipboard delete — real button, not a bare
                            // glyph, so it has its own hit area away from the
                            // scrollbar lane instead of a click landing as a scroll.
                            Rectangle {
                                visible: root.mode === "clip"
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: Theme.radiusSm
                                color: clipDeleteMa.containsMouse ? Theme.withAlpha(Theme.error, 0.18) : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "\u{f1f8}"   // trash can
                                    color: clipDeleteMa.containsMouse ? Theme.error : Theme.surfaceTextDim
                                    font.family: Theme.fontFamily
                                    font.pointSize: Theme.labelLarge
                                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                                }

                                MouseArea {
                                    id: clipDeleteMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.deleteClip(modelData)
                                }
                            }
                        }

                        // Leave the trash-button's column uncovered — this
                        // overlay sits on top of the RowLayout in stacking
                        // order, so without the margin it swallows clicks
                        // meant for the delete button before they ever reach it.
                        MouseArea {
                            anchors.fill: parent
                            anchors.rightMargin: root.mode === "clip" ? 34 : 0
                            hoverEnabled: true
                            onEntered: root.selectedIdx = index
                            onClicked: root.activate(modelData)
                        }
                    }

                    Item {
                        anchors.centerIn: parent
                        visible: root.results.length === 0 && root.mode !== "calc"
                        Text {
                            anchors.centerIn: parent
                            text: root.mode === "apps"  ? "No apps found"
                                : root.mode === "clip"  ? (root.allClip.length === 0 ? "Clipboard is empty" : "No matches")
                                : root.mode === "emoji" ? "Loading emoji..."
                                : root.mode === "words" ? (root.query === "" ? "Type to search" : "No matches")
                                : ""
                            color: Theme.surfaceTextDim
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.labelLarge
                        }
                    }
                }

                // Clipboard preview pane
                Rectangle {
                    Layout.preferredWidth: 200
                    Layout.fillHeight: true
                    visible: root.mode === "clip"
                    radius: Theme.radiusMd
                    color: Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity)
                    border.color: Theme.cardBorder()
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Theme.spacingSm

                        Image {
                            id: imagePreview
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.margins: Theme.spacingMd
                            visible: root.results.length > 0 && root.results[root.selectedIdx] !== undefined
                                && root.results[root.selectedIdx].kind === "image"
                            source: {
                                var it = (root.results.length > 0 && root.results[root.selectedIdx])
                                    ? root.results[root.selectedIdx] : null
                                return (it && it.img) ? "data:image/png;base64," + it.img : ""
                            }
                            sourceSize: Qt.size(188, 400)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        Flickable {
                            id: previewFlick
                            visible: !imagePreview.visible
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.margins: Theme.spacingMd
                            clip: true
                            contentWidth: width
                            contentHeight: previewText.implicitHeight

                            Text {
                                id: previewText
                                width: previewFlick.width
                                text: {
                                    var it = (root.results.length > 0 && root.results[root.selectedIdx])
                                        ? root.results[root.selectedIdx] : null
                                    if (!it) return "Select an entry to preview"
                                    if (it.kind === "image") return ""
                                    return it.text || ""
                                }
                                color: Theme.surfaceTextVariant
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.labelSmall
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                parent: previewFlick
                                anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
                            }
                        }
                    }
                }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.mode === "clip"
                        ? "↑↓ navigate  ·  enter copy  ·  del or ✕ remove  ·  tab switch mode  ·  esc close"
                        : "↑↓ / jk navigate  ·  enter select  ·  tab switch mode  ·  esc close"
                    color: Theme.surfaceTextDim
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.labelSmall
                }
            }
        }
    }
}
