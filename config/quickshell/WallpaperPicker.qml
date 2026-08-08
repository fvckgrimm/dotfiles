import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// File-manager style wallpaper browser — centered full-screen overlay
// (same window/keyboard pattern as LauncherPopup so typing + focus work).
PanelWindow {
    id: root

    required property var barWindow
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell:wallpaper"
    exclusiveZone: 0
    anchors {}

    implicitWidth:  screen.width
    implicitHeight: screen.height
    color: "transparent"
    screen: barWindow ? barWindow.screen : undefined

    readonly property int cardW: 940
    readonly property int cardH: 700

    // ── State ──────────────────────────────────────────────────────────────
    // `allFiles` is the full sorted path list of the current view (a dir from
    // wallpaperDirs, or the curated favorites when currentPath === "").
    // `shown` is the search-filtered, incrementally-loaded slice that feeds the
    // grid/list; scrolling near the bottom grows loadCount (lazy loading).
    property var   allFiles: []
    property string currentPath: ""       // "" = favorites
    property string search: ""
    property string error: ""
    property string lastAppliedPath: ""
    property bool   loading: false
    property bool   addingDir: false
    property bool   addingRecursive: false
    property string addDirError: ""
    property bool   _closing: false
    property bool   _listing: false
    property string _buffer: ""
    property int    highlightIdx: -1
    property string prevWall: ""
    property int    batchSize: 80
    property int    loadCount: 80

    readonly property var shown: {
        var list = root.allFiles
        if (root.search !== "") {
            var q = root.search.toLowerCase()
            var f = []
            for (var i = 0; i < list.length; i++)
                if (list[i].toLowerCase().indexOf(q) !== -1) f.push(list[i])
            list = f
        }
        return list.slice(0, root.loadCount)
    }

    // ── Wallpaper color-match theme preview ────────────────────────────
    // previewPalette is the palette qs-theme.py derived for the highlighted
    // wallpaper; the mock below renders a mini shell with it. `pp` resolves
    // to a neutral default so the preview never shows raw nulls.
    property var   previewPalette: null
    property string previewPath: ""
    readonly property var pp: root.previewPalette ?? {
        background: "#12161d", surface: "#161b23", surfaceContainer: "#1b212b",
        surfaceContainerLow: "#161b23", surfaceContainerHigh: "#212836",
        surfaceContainerLowest: "#0a0d12", outline: "#3a4354",
        primary: "#7dd8ff", primaryText: "#00303f",
        secondary: "#e3b872", tertiary: "#c9a8f0", success: "#7ee0a8",
        surfaceText: "#e2e6ee", surfaceTextVariant: "#98a2b8", surfaceTextDim: "#5c6579"
    }

    readonly property int thumbW: 184
    readonly property int thumbH: 104
    readonly property int cellW:  root.thumbW + 14
    readonly property int cellH:  root.thumbH + 32

    // ── Public API ─────────────────────────────────────────────────────────
    function open() {
        root._closing = false
        root.previewPalette = null
        root.addingDir = false
        root.addingRecursive = false
        root.addDirError = ""
        root.lastAppliedPath = SettingsService.dynamicWallpaper
        root.visible = true
        snapshotProc.running = true
        if (SettingsService.favorites.length > 0) root.loadFavorites()
        else if (SettingsService.wallpaperDirs.length > 0) root.loadDir(SettingsService.wallpaperDirs[0])
        else root.loadFavorites()
        Qt.callLater(() => { if (searchInput) searchInput.forceActiveFocus() })
    }

    function close(confirm) {
        if (!root.visible || root._closing) return
        root._closing = true
        if (!confirm && root.prevWall !== "") root.applyWall(root.prevWall)
        else if (confirm && root.highlightIdx >= 0 && root.highlightIdx < root.shown.length) {
            var path = root.shown[root.highlightIdx]
            root.lastAppliedPath = path
            root.applyWall(path)
            if (SettingsService.dynamicTheme) SettingsService.applyDynamicTheme(path)
        }
        closeTimer.start()
    }

    function applyWall(path) {
        if (!path || path === "") return
        Quickshell.execDetached([
            "awww", "img",
            "-o", barWindow && barWindow.screen ? barWindow.screen.name : "DP-1",
            "--transition-type", "fade",
            "--transition-duration", "0.3",
            path
        ])
    }

    // Run the color matcher for a wallpaper (used for the live theme preview).
    // bash -c expands `~` (Process runs args without a shell).
    function previewWall(path) {
        if (!path || path === "") return
        themePreviewProc.command = ["bash", "-c", "python3 -u ~/.scripts/qs-theme.py " + JSON.stringify(path)]
        themePreviewProc.running = true
    }

    // ── Views ───────────────────────────────────────────────────────────────
    function loadDir(path) {
        if (!path || path === "") return
        root.currentPath = path
        root.search = ""
        if (searchInput) searchInput.text = ""
        root.error = ""
        root.loading = true
        root._listing = true
        root._buffer = ""
        root.allFiles = []
        root.loadCount = root.batchSize
        root.highlightIdx = -1
        var dir = path.replace(/^~/, "$HOME")
        var depth = SettingsService.isRecursive(path) ? "" : " -maxdepth 2"
        var script = "find " + JSON.stringify(dir) + depth + " -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.avif' \\) | sort | head -n 3000"
        listProc.command = ["bash", "-c", script]
        listProc.running = true
        Qt.callLater(() => { if (searchInput) searchInput.forceActiveFocus() })
    }

    function loadFavorites() {
        root.currentPath = ""
        root.search = ""
        if (searchInput) searchInput.text = ""
        root.error = ""
        root._listing = false
        root.loading = false
        root.allFiles = SettingsService.favorites.slice()
        root.loadCount = root.batchSize
        root.highlightIdx = -1
        Qt.callLater(() => { if (searchInput) searchInput.forceActiveFocus() })
    }

    function _finishList() {
        root._listing = false
        root.loading = false
        var lines = root._buffer.split("\n")
        var out = []
        for (var i = 0; i < lines.length; i++) {
            var l = lines[i].trim()
            if (l !== "") out.push(l)
        }
        root.allFiles = out
        if (out.length === 0) root.error = "no images found in this folder"
        root.ensureFilled()
    }

    // ── Places / favorites management ──────────────────────────────────────
    // Places must be absolute paths; expand `~` and reject anything relative.
    function expandPath(raw) {
        var p = (raw || "").trim()
        if (p === "") return ""
        if (p[0] === "~") p = SettingsService.expandHome(p)
        if (p[0] !== "/") return ""
        return p.replace(/\/+$/, "")
    }

    function addDir(raw) {
        var path = root.expandPath(raw)
        if (path === "") {
            root.addDirError = "absolute path required (e.g. /home/you/Pictures/walls)"
            return
        }
        root.addDirError = ""
        if (SettingsService.wallpaperDirs.indexOf(path) === -1) {
            var d = SettingsService.wallpaperDirs.slice()
            d.push(path)
            SettingsService.wallpaperDirs = d
        }
        if (root.addingRecursive) SettingsService.setRecursive(path, true)
        root.addingDir = false
        root.addingRecursive = false
        root.loadDir(path)
    }

    function removeDir(path) {
        var idx = SettingsService.wallpaperDirs.indexOf(path)
        if (idx !== -1) {
            var d = SettingsService.wallpaperDirs.slice()
            d.splice(idx, 1)
            SettingsService.wallpaperDirs = d
        }
        // A removed dir must not linger in the recursive scan list.
        if (SettingsService.isRecursive(path)) SettingsService.setRecursive(path, false)
        if (root.currentPath === path) root.loadFavorites()
    }

    function placeName(path) {
        var p = path.replace(/\/+$/, "").replace(/.*\//, "")
        return p === "" ? path : p
    }

    function toggleFavoriteAt(index) {
        if (index < 0 || index >= root.shown.length) return
        var p = root.shown[index]
        SettingsService.isFavorite(p) ? SettingsService.unfavorite(p) : SettingsService.favorite(p)
    }

    // ── Lazy loading ───────────────────────────────────────────────────────
    function currentView() {
        return SettingsService.wallpaperView === "list" ? listView : gridView
    }

    // Keep loading batches until the viewport is full (or everything is in).
    function ensureFilled() {
        var guard = 0
        while (guard++ < 500 && root.loadCount < root.allFiles.length) {
            var v = root.currentView()
            if (v && v.contentHeight > v.height) return
            root.loadCount += root.batchSize
        }
    }

    function maybeLoadMore() {
        if (root.loadCount >= root.allFiles.length) return
        var v = root.currentView()
        if (!v || v.contentHeight <= v.height) return
        if (v.contentY + v.height >= v.contentHeight - 240) root.loadCount += root.batchSize
    }

    function columns() {
        return Math.max(1, Math.floor(gridView.width / gridView.cellWidth))
    }

    function moveHighlight(d) {
        if (root.shown.length === 0) return
        if (root.highlightIdx < 0) { root.highlightIdx = 0; return }
        root.highlightIdx = Math.max(0, Math.min(root.highlightIdx + d, root.shown.length - 1))
    }

    // ── Reactive plumbing ───────────────────────────────────────────────────
    onHighlightIdxChanged: {
        if (root.highlightIdx >= 0 && root.highlightIdx < root.shown.length) {
            root.applyWall(root.shown[root.highlightIdx])
            themePreviewTimer.restart()
        }
    }

    onShownChanged: {
        if (root.shown.length === 0) root.highlightIdx = -1
        else if (root.highlightIdx >= root.shown.length) root.highlightIdx = root.shown.length - 1
        root.ensureFilled()
    }

    // Debounced so fast scrolling doesn't spawn a python process per frame.
    Timer {
        id: themePreviewTimer
        interval: 220
        onTriggered: {
            if (root.highlightIdx >= 0 && root.highlightIdx < root.shown.length) {
                root.previewPath = root.shown[root.highlightIdx]
                root.previewWall(root.previewPath)
            }
        }
    }

    // Parse the matcher output for the theme preview mock.
    Process {
        id: themePreviewProc
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var obj = JSON.parse(data.trim())
                    if (obj.fallback) { root.previewPalette = null; return }
                    root.previewPalette = obj.palette
                } catch (e) {
                    console.log("qs-theme preview parse error: " + e)
                    root.previewPalette = null
                }
            }
        }
    }

    Process {
        id: listProc
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { root._buffer += data }
        }
        onRunningChanged: {
            if (!running && root._listing) root._finishList()
        }
    }

    Process {
        id: snapshotProc
        command: ["bash", "-c", "awww query 2>/dev/null | grep 'image:' | head -1 | sed 's/.*image: //'"]
        running: false
        stdout: SplitParser { onRead: data => { root.prevWall = data.trim(); root.previewWall(root.prevWall) } }
    }

    Timer { id: closeTimer; interval: 150; onTriggered: { root.visible = false; root._closing = false } }

    // ── UI ──────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Theme.withAlpha("#000000", 0.55)

        MouseArea { anchors.fill: parent; onClicked: root.close(false) }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width:  Math.min(root.cardW, parent.width - 48)
            height: Math.min(root.cardH, parent.height - 48)
            radius: Theme.radiusXl
            color: Theme.cardColor()
            border.color: Theme.cardBorder()
            border.width: 1

            // Swallow clicks on the card chrome (don't fall through to backdrop).
            MouseArea { anchors.fill: parent; onClicked: {} }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingMd
                spacing: Theme.spacingSm

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSm

                    // Search / filter (also the keyboard handler for the whole
                    // picker — kept focused so arrows/enter always work).
                    Rectangle {
                        Layout.preferredWidth: 260
                        Layout.preferredHeight: 28
                        radius: Theme.radiusFull
                        color: Theme.surfaceContainerLow
                        clip: true

                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            spacing: 6
                            Text {
                                text: "\u{f002}"
                                color: Theme.surfaceTextVariant
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.labelLarge
                            }
                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                color: Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.labelLarge
                                selectByMouse: true
                                verticalAlignment: TextInput.AlignVCenter
                                focus: true

                                onTextEdited: root.search = text

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Escape) {
                                        if (root.search !== "") { searchInput.text = ""; root.search = "" }
                                        else root.close(false)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        root.close(true)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Down) {
                                        root.moveHighlight(root.columns())
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Up) {
                                        root.moveHighlight(-root.columns())
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Right) {
                                        root.moveHighlight(1)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Left) {
                                        root.moveHighlight(-1)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Home) {
                                        root.highlightIdx = 0
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_End) {
                                        root.highlightIdx = root.shown.length - 1
                                        event.accepted = true
                                    } else if (root.search === "" && event.key === Qt.Key_J) {
                                        root.moveHighlight(root.columns())
                                        event.accepted = true
                                    } else if (root.search === "" && event.key === Qt.Key_K) {
                                        root.moveHighlight(-root.columns())
                                        event.accepted = true
                                    } else if (root.search === "" && event.key === Qt.Key_H) {
                                        root.moveHighlight(-1)
                                        event.accepted = true
                                    } else if (root.search === "" && event.key === Qt.Key_L) {
                                        root.moveHighlight(1)
                                        event.accepted = true
                                    } else if (root.search === "" && event.key === Qt.Key_F) {
                                        if (root.highlightIdx < 0) root.highlightIdx = 0
                                        root.toggleFavoriteAt(root.highlightIdx)
                                        event.accepted = true
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "match theme"
                        color: Theme.surfaceTextDim
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.labelSmall
                    }

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 18
                        radius: Theme.radiusFull
                        color: SettingsService.dynamicTheme
                            ? Theme.withAlpha(Theme.tertiary, 0.3)
                            : Theme.surfaceContainerHigh
                        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                        Rectangle {
                            x: SettingsService.dynamicTheme ? 16 : 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14; height: 14; radius: 7
                            color: SettingsService.dynamicTheme ? Theme.tertiary : Theme.surfaceTextDim
                            Behavior on x { NumberAnimation { duration: Theme.motionMedium; easing.type: Theme.easingStandard } }
                        }
                        MouseArea { anchors.fill: parent; onClicked: SettingsService.dynamicTheme = !SettingsService.dynamicTheme }
                    }

                    Rectangle {
                        width: 28; height: 28; radius: Theme.radiusSm
                        color: SettingsService.wallpaperView === "grid"
                            ? Theme.withAlpha(Theme.primary, 0.3) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "\u{f009}"
                            color: SettingsService.wallpaperView === "grid" ? Theme.primary : Theme.surfaceTextDim
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.labelLarge
                        }
                        MouseArea { anchors.fill: parent; onClicked: SettingsService.wallpaperView = "grid" }
                    }

                    Rectangle {
                        width: 28; height: 28; radius: Theme.radiusSm
                        color: SettingsService.wallpaperView === "list"
                            ? Theme.withAlpha(Theme.primary, 0.3) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "\u{f0ca}"
                            color: SettingsService.wallpaperView === "list" ? Theme.primary : Theme.surfaceTextDim
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.labelLarge
                        }
                        MouseArea { anchors.fill: parent; onClicked: SettingsService.wallpaperView = "list" }
                    }

                    Text {
                        text: "✕"
                        color: Theme.surfaceTextVariant
                        font.pointSize: Theme.titleMedium
                        MouseArea { anchors.fill: parent; onClicked: root.close(false) }
                    }
                }

                // ── Live theme preview mock ─────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 128
                    radius: Theme.radiusLg
                    color: root.pp.background
                    border.color: root.pp.outlineVariant
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingMd
                        spacing: Theme.spacingSm

                        Rectangle {
                            Layout.fillWidth: true
                            height: 22
                            radius: Theme.radiusSm
                            color: root.pp.surfaceContainerLowest

                            RowLayout {
                                anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                                spacing: 4
                                Rectangle { width: 8; height: 8; radius: 4; color: root.pp.primary }
                                Rectangle {
                                    width: 36; height: 12; radius: 4
                                    color: root.pp.primary
                                    Text {
                                        anchors.centerIn: parent
                                        text: "cpu"
                                        color: root.pp.primaryText
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.labelSmall
                                        font.bold: true
                                    }
                                }
                                Rectangle { width: 30; height: 12; radius: 4; color: root.pp.surfaceContainer }
                                Rectangle { width: 36; height: 12; radius: 4; color: root.pp.secondary }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    width: 30; height: 12; radius: 4
                                    color: root.pp.surfaceContainerHigh
                                    Text {
                                        anchors.centerIn: parent
                                        text: "10:30"
                                        color: root.pp.surfaceText
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.labelSmall
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Theme.spacingMd

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: Theme.radiusMd
                                border.color: root.pp.outline
                                border.width: 1
                                color: root.pp.surfaceContainerLow

                                ColumnLayout {
                                    anchors { fill: parent; margins: Theme.spacingMd }
                                    spacing: Theme.spacingSm

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingSm
                                        Text {
                                            text: "\u{f4bc}"
                                            color: root.pp.primary
                                            font.family: Theme.fontFamily
                                            font.pointSize: Theme.titleSmall
                                        }
                                        Text {
                                            text: "Sample heading"
                                            color: root.pp.surfaceText
                                            font.family: Theme.fontFamily
                                            font.pointSize: Theme.bodySmall
                                            font.bold: true
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: "42%"
                                            color: root.pp.surfaceTextVariant
                                            font.family: Theme.fontFamily
                                            font.pointSize: Theme.bodySmall
                                        }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 4
                                        radius: 2
                                        color: root.pp.surfaceContainerHigh
                                        Rectangle {
                                            width: parent.width * 0.42
                                            height: parent.height
                                            radius: 2
                                            color: root.pp.primary
                                        }
                                    }
                                    Item { Layout.fillHeight: true }
                                    Text {
                                        Layout.fillWidth: true
                                        text: root.previewPalette
                                            ? "this palette will be applied to the whole shell"
                                            : "no dominant accent in this wallpaper — falls back to Default"
                                        color: root.previewPalette ? root.pp.surfaceTextDim : root.pp.surfaceTextVariant
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.labelSmall
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 170
                                Layout.fillHeight: true
                                radius: Theme.radiusMd
                                color: root.pp.surfaceContainerLowest
                                border.color: root.pp.outline
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingMd
                                    spacing: Theme.spacingSm

                                    Text {
                                        Layout.fillWidth: true
                                        elide: Text.ElideMiddle
                                        text: root.previewPath === ""
                                            ? "current wallpaper"
                                            : root.previewPath.replace(/.*\//, "")
                                        color: root.pp.surfaceText
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.labelSmall
                                        font.bold: true
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        text: SettingsService.dynamicTheme
                                            ? "theme follows the wallpaper"
                                            : "theme matching is off"
                                        color: root.pp.surfaceTextVariant
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.labelSmall
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Main split: sidebar + browser ───────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.spacingMd

                    // Sidebar
                    ColumnLayout {
                        Layout.preferredWidth: 190
                        Layout.fillHeight: true
                        spacing: Theme.spacingXs

                        Text {
                            text: "WALLPAPERS"
                            color: Theme.surfaceTextVariant
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.labelLarge
                            font.bold: true
                        }

                        Rectangle {
                            id: favRow
                            Layout.fillWidth: true
                            height: 30
                            radius: Theme.radiusSm
                            color: favMa.containsMouse
                                ? Theme.withAlpha(Theme.primary, 0.18)
                                : (root.currentPath === "" ? Theme.withAlpha(Theme.primary, 0.10) : "transparent")

                            RowLayout {
                                anchors { fill: parent; leftMargin: Theme.spacingMd; rightMargin: Theme.spacingMd }
                                spacing: 8
                                Text {
                                    text: "\u{f004}"
                                    color: root.currentPath === "" ? Theme.error : Theme.surfaceTextVariant
                                    font.family: Theme.fontFamily
                                    font.pointSize: Theme.labelLarge
                                }
                                Text {
                                    text: "Favorites"
                                    Layout.fillWidth: true
                                    elide: Text.ElideMiddle
                                    color: root.currentPath === "" ? Theme.surfaceText : Theme.surfaceTextVariant
                                    font.family: Theme.fontFamily
                                    font.pointSize: Theme.labelLarge
                                }
                                Text {
                                    text: SettingsService.favorites.length
                                    color: Theme.surfaceTextDim
                                    font.family: Theme.fontFamily
                                    font.pointSize: Theme.labelSmall
                                }
                            }
                            MouseArea {
                                id: favMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.loadFavorites()
                            }
                        }

                        Text {
                            text: "PLACES"
                            color: Theme.surfaceTextDim
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.labelSmall
                        }

                        Repeater {
                            model: SettingsService.wallpaperDirs
                            delegate: Item {
                                required property string modelData
                                required property int    index

                                Layout.fillWidth: true
                                Layout.preferredHeight: 30

                                readonly property bool isCurrent: root.currentPath === modelData

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Theme.radiusSm
                                    color: rowMa.containsMouse
                                        ? Theme.withAlpha(Theme.primary, 0.18)
                                        : (isCurrent ? Theme.withAlpha(Theme.primary, 0.10) : "transparent")

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: Theme.spacingMd; rightMargin: Theme.spacingMd }
                                        spacing: 8
                                        Text {
                                            text: "\u{f07b}"
                                            color: isCurrent ? Theme.primary : Theme.surfaceTextVariant
                                            font.family: Theme.fontFamily
                                            font.pointSize: Theme.labelLarge
                                        }
                                        Text {
                                            text: root.placeName(modelData)
                                            Layout.fillWidth: true
                                            elide: Text.ElideMiddle
                                            color: isCurrent ? Theme.surfaceText : Theme.surfaceTextVariant
                                            font.family: Theme.fontFamily
                                            font.pointSize: Theme.labelLarge
                                        }
                                    }

                                    MouseArea {
                                        id: rowMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.loadDir(modelData)
                                    }

                                    // Recursive (scan subfolders) toggle
                                    Text {
                                        id: recIcon
                                        anchors.right: parent.right
                                        anchors.rightMargin: 30
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "\u{21f5}"
                                        visible: SettingsService.isRecursive(modelData) || rowMa.containsMouse
                                        color: SettingsService.isRecursive(modelData) ? Theme.primary : Theme.surfaceTextDim
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.labelSmall
                                        font.bold: SettingsService.isRecursive(modelData)
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: SettingsService.setRecursive(modelData, !SettingsService.isRecursive(modelData))
                                        }
                                    }

                                    // Remove place
                                    Text {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "\u{f057}"
                                        visible: rowMa.containsMouse
                                        color: Theme.error
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.labelSmall
                                        MouseArea { anchors.fill: parent; onClicked: root.removeDir(modelData) }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: addRow
                            Layout.fillWidth: true
                            height: 28
                            radius: Theme.radiusSm
                            color: addMa.containsMouse ? Theme.withAlpha(Theme.primary, 0.15) : "transparent"
                            visible: !root.addingDir

                            RowLayout {
                                anchors { fill: parent; leftMargin: Theme.spacingMd; rightMargin: Theme.spacingMd }
                                spacing: 8
                                Text {
                                    text: "+"
                                    color: Theme.primary
                                    font.family: Theme.fontFamily
                                    font.pointSize: Theme.labelLarge
                                    font.bold: true
                                }
                                Text {
                                    text: "add folder"
                                    color: Theme.primary
                                    font.family: Theme.fontFamily
                                    font.pointSize: Theme.labelLarge
                                }
                            }
                            MouseArea {
                                id: addMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: { root.addDirError = ""; root.addingDir = true; dirFocusTimer.start() }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 26
                            radius: Theme.radiusSm
                            color: Theme.surfaceContainerLow
                            visible: root.addingDir
                            clip: true

                            RowLayout {
                                anchors { fill: parent; leftMargin: Theme.spacingMd; rightMargin: Theme.spacingMd }
                                spacing: 6

                                TextInput {
                                    id: dirInput
                                    Layout.fillWidth: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.surfaceText
                                    font.family: Theme.fontFamily
                                    font.pointSize: Theme.labelLarge
                                    selectByMouse: true
                                    Keys.onReturnPressed: root.addDir(dirInput.text)
                                    Keys.onEscapePressed: {
                                        root.addingDir = false
                                        root.addingRecursive = false
                                        root.addDirError = ""
                                        Qt.callLater(() => { if (searchInput) searchInput.forceActiveFocus() })
                                    }
                                }

                                Text {
                                    text: "⇵"
                                    color: root.addingRecursive ? Theme.primary : Theme.surfaceTextDim
                                    font.family: Theme.fontFamily
                                    font.pointSize: Theme.labelLarge
                                    font.bold: root.addingRecursive
                                    MouseArea { anchors.fill: parent; onClicked: root.addingRecursive = !root.addingRecursive }
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            visible: root.addDirError !== ""
                            text: root.addDirError
                            color: Theme.error
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.labelSmall
                        }

                        Timer { id: dirFocusTimer; interval: 10; onTriggered: dirInput.forceActiveFocus() }

                        Item { Layout.fillHeight: true }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: "hover previews · click sets · esc cancels"
                            color: Theme.surfaceTextDim
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.labelSmall
                        }
                    }

                    Rectangle { Layout.fillHeight: true; width: 1; color: Theme.outlineVariant }

                    // Browser
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Theme.spacingSm

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingSm

                            Text {
                                Layout.preferredWidth: 320
                                elide: Text.ElideMiddle
                                text: root.currentPath === "" ? "Favorites" : root.currentPath
                                color: Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.labelLarge
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: {
                                    if (root.search !== "") return root.shown.length + " of " + root.allFiles.length
                                    return root.allFiles.length + (root.currentPath === "" ? " favorites" : " wallpapers")
                                }
                                color: Theme.surfaceTextVariant
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.labelSmall
                            }

                            Text {
                                text: root.loading ? "loading…" : root.error
                                color: root.error !== "" ? Theme.error : Theme.surfaceTextDim
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.labelSmall
                            }
                        }

                        Item {
                            id: contentArea
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            GridView {
                                id: gridView
                                anchors.fill: parent
                                clip: true
                                visible: SettingsService.wallpaperView === "grid"
                                cellWidth: root.cellW
                                cellHeight: root.cellH
                                model: root.shown
                                onContentYChanged: root.maybeLoadMore()
                                onContentHeightChanged: root.maybeLoadMore()
                                onWidthChanged: root.ensureFilled()
                                onHeightChanged: root.ensureFilled()

                                delegate: Item {
                                    required property string modelData
                                    required property int    index

                                    width:  gridView.cellWidth
                                    height: gridView.cellHeight

                                    readonly property bool isHighlighted: root.highlightIdx === index
                                    readonly property bool isFav: SettingsService.isFavorite(modelData)
                                    readonly property bool isApplied: root.lastAppliedPath === modelData

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: root.highlightIdx = index
                                        onClicked: root.close(true)
                                    }

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: parent.top
                                        anchors.topMargin: 4
                                        width: root.thumbW
                                        height: root.thumbH
                                        radius: Theme.radiusMd
                                        clip: true
                                        color: Theme.surfaceContainer

                                        scale: isHighlighted ? 1.03 : 1.0
                                        Behavior on scale { NumberAnimation { duration: Theme.motionFast } }

                                        Image {
                                            anchors.fill: parent
                                            source: "file://" + modelData
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            cache: true
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Theme.radiusMd
                                            color: "black"
                                            opacity: isHighlighted ? 0.0 : 0.45
                                            Behavior on opacity { NumberAnimation { duration: Theme.motionMedium } }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Theme.radiusMd
                                            color: "transparent"
                                            border.width: isHighlighted ? 2 : (isApplied ? 2 : 0)
                                            border.color: isApplied ? Theme.success : Theme.tertiary
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        width: root.thumbW
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideMiddle
                                        text: modelData.replace(/.*\//, "")
                                        color: isHighlighted ? Theme.surfaceText : Theme.surfaceTextVariant
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.labelSmall
                                    }

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.topMargin: 10
                                        width: 24; height: 24; radius: 12
                                        color: Theme.withAlpha(Theme.surfaceContainerLowest, 0.75)
                                        Text {
                                            anchors.centerIn: parent
                                            text: "\u{f004}"
                                            color: isFav ? Theme.error : Theme.surfaceTextDim
                                            font.family: Theme.fontFamily
                                            font.pointSize: Theme.labelLarge
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: root.toggleFavoriteAt(index)
                                        }
                                    }
                                }
                            }

                            ListView {
                                id: listView
                                anchors.fill: parent
                                clip: true
                                visible: SettingsService.wallpaperView === "list"
                                spacing: 4
                                model: root.shown
                                onContentYChanged: root.maybeLoadMore()
                                onContentHeightChanged: root.maybeLoadMore()
                                onWidthChanged: root.ensureFilled()
                                onHeightChanged: root.ensureFilled()

                                delegate: Item {
                                    required property string modelData
                                    required property int    index

                                    width:  listView.width
                                    height: 62

                                    readonly property bool isHighlighted: root.highlightIdx === index
                                    readonly property bool isFav: SettingsService.isFavorite(modelData)
                                    readonly property bool isApplied: root.lastAppliedPath === modelData

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: root.highlightIdx = index
                                        onClicked: root.close(true)
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Theme.radiusSm
                                        color: isHighlighted ? Theme.withAlpha(Theme.primary, 0.12) : "transparent"
                                        border.width: isApplied ? 1 : 0
                                        border.color: Theme.success

                                        RowLayout {
                                            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                            spacing: 10

                                            Rectangle {
                                                width: 88; height: 50
                                                radius: Theme.radiusSm
                                                clip: true
                                                color: Theme.surfaceContainer
                                                Image {
                                                    anchors.fill: parent
                                                    source: "file://" + modelData
                                                    fillMode: Image.PreserveAspectCrop
                                                    asynchronous: true
                                                    cache: true
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text {
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideMiddle
                                                    text: modelData.replace(/.*\//, "")
                                                    color: isHighlighted ? Theme.surfaceText : Theme.surfaceTextVariant
                                                    font.family: Theme.fontFamily
                                                    font.pointSize: Theme.labelLarge
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideMiddle
                                                    text: modelData
                                                    color: Theme.surfaceTextDim
                                                    font.family: Theme.fontFamily
                                                    font.pointSize: Theme.labelSmall
                                                }
                                            }

                                            MouseArea {
                                                Layout.preferredWidth: 24
                                                Layout.preferredHeight: 24
                                                onClicked: root.toggleFavoriteAt(index)
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "\u{f004}"
                                                    color: isFav ? Theme.error : Theme.surfaceTextDim
                                                    font.family: Theme.fontFamily
                                                    font.pointSize: Theme.labelLarge
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: root.shown.length === 0 && !root.loading
                                text: root.error !== ""
                                    ? root.error
                                    : (root.currentPath === ""
                                        ? "no favorites yet — hover a wallpaper and press F"
                                        : (root.search !== "" ? "no matches" : "folder is empty"))
                                color: Theme.surfaceTextDim
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.labelLarge
                            }
                        }
                    }
                }
            }
        }
    }
}
