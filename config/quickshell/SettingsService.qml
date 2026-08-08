pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property bool loadedFromConfig: false
    property bool hasBattery: false

    // Settings (Default to true, but overridden by config.json once loaded)
    property bool showBattery: true
    property bool showCpu: true
    property bool showMemory: true
    property bool showStorage: true
    property bool showTemp: true
    property bool showNetwork: true
    property bool showMedia: true
    property bool showWeather: true
    property bool showWorkspaces: true
    property bool showStats: true

    // At-a-glance cards in the Dashboard stats tab — independent of the
    // bar-widget toggles above, so cards can show in the dashboard even
    // when the matching widget is hidden from the bar.
    property bool showGlanceCpu: true
    property bool showGlanceMemory: true
    property bool showGlanceStorage: true
    property bool showGlanceTemp: true
    property bool showGlanceBattery: true
    property bool showGlanceNetwork: true

    // Wallpaper browser: `wallpaperDirs` are the "Places" browsed in the
    // picker sidebar (stored as absolute paths); `wallpaperRecursive` holds
    // the subset of dirs that are scanned into subfolders too; `favorites`
    // is the curated list persisted to ~/.config/quickshell/wallpapers.txt;
    // `wallpaperView` is the grid/list toggle preference.
    property var wallpaperDirs: ["~/Pictures/wallpapers"]
    property var wallpaperRecursive: []
    property var favorites: []
    property string wallpaperView: "grid"  // "grid" | "list"
    property string dashboardPosition: "right"  // "left", "center", "right"
    property string theme: "default"  // key into Theme.palettes (Theme.applyTheme via onThemeChanged)
    // Wallpaper color-match theme: dynamicTheme = master switch, dynamicWallpaper
    // remembers the last wallpaper the palette was generated from (so the theme
    // can be re-derived at boot without re-selecting).
    property bool   dynamicTheme: true
    property string dynamicWallpaper: ""
    // Dashboard Home tab profile card: avatar image + banner background.
    // Empty string = fall back to a glyph / themed gradient.
    property string profileImage: ""
    property string profileBanner: ""

    // Resolved profile art from standard files: ~/.face* (avatar) and
    // ~/.banner* (banner background). Detected at startup (and re-probed
    // periodically so files can be hot-swapped while the shell is running);
    // if found they take precedence over profileImage/profileBanner (which
    // remain manual overrides in the Dashboard → Settings → PROFILE page).
    // The stamps hold `<size>|<mtime>` and only signal *change*; the Bust
    // counters are bumped on change so the UI can append a cache-busting URL
    // fragment to force a reload of the image.
    property string facePath: ""
    property string faceStamp: ""
    property int faceBust: 0
    property string bannerPath: ""
    property string bannerStamp: ""
    property int bannerBust: 0

    Process {
        id: faceProbe
        command: ["bash", "-c", "for f in ~/.face ~/.face.png ~/.face.jpg ~/.face.jpeg ~/.face.gif ~/.face.webp; do [ -f \"$f\" ] && { s=$(stat -c '%s|%Y' \"$f\") && echo \"$f|$s\" && exit 0; }; done; echo \"\""]
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var line = data.trim()
                if (line === "") {
                    if (root.facePath !== "" || root.faceStamp !== "") { root.facePath = ""; root.faceStamp = ""; root.faceBust++ }
                    return
                }
                var i = line.indexOf("|")
                if (i < 0) return
                var p = line.slice(0, i)
                var st = line.slice(i + 1)
                if (root.facePath !== p || root.faceStamp !== st) {
                    root.facePath = p
                    root.faceStamp = st
                    root.faceBust++
                }
            }
        }
    }

    Process {
        id: bannerProbe
        command: ["bash", "-c", "for f in ~/.banner ~/.banner.png ~/.banner.jpg ~/.banner.jpeg ~/.banner.gif ~/.banner.webp; do [ -f \"$f\" ] && { s=$(stat -c '%s|%Y' \"$f\") && echo \"$f|$s\" && exit 0; }; done; echo \"\""]
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var line = data.trim()
                if (line === "") {
                    if (root.bannerPath !== "" || root.bannerStamp !== "") { root.bannerPath = ""; root.bannerStamp = ""; root.bannerBust++ }
                    return
                }
                var i = line.indexOf("|")
                if (i < 0) return
                var p = line.slice(0, i)
                var st = line.slice(i + 1)
                if (root.bannerPath !== p || root.bannerStamp !== st) {
                    root.bannerPath = p
                    root.bannerStamp = st
                    root.bannerBust++
                }
            }
        }
    }

    // Re-probe the profile art files so swapping ~/.face* / ~/.banner* takes
    // effect without restarting the shell.
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            faceProbe.running = true
            bannerProbe.running = true
        }
    }

    // Expand a leading `~` to the real home directory (stored dirs are absolute).
    // Qt.homeDir() is NOT exposed in this Quickshell build, so resolve $HOME via
    // a bash Process at startup and re-normalize dirs once it lands.
    property string homeDir: ""

    function expandHome(p) {
        if (!p || p[0] !== "~") return p
        if (root.homeDir !== "") return root.homeDir + p.slice(1)
        return p
    }

    // Convert a path back to a `~`-relative (portable) form for persisting.
    // Paths stay absolute in memory (the picker matches on absolute paths) but
    // settings.json stores `~/...` so the config is machine-independent.
    function toPortable(p) {
        if (!p || root.homeDir === "") return p
        var h = root.homeDir
        if (p === h) return "~"
        if (p.indexOf(h + "/") === 0) return "~" + p.slice(h.length)
        return p
    }

    Process {
        id: homeProc
        command: ["bash", "-c", "echo $HOME"]
        running: true
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var h = data.trim()
                if (h !== "" && root.homeDir !== h) root.homeDir = h
            }
        }
    }

    onHomeDirChanged: {
        if (root.homeDir === "" || !root.loadedFromConfig) return
        var changed = false
        var d = root.wallpaperDirs.map(p => {
            var e = root.expandHome(p)
            if (e !== p) changed = true
            return e
        })
        if (changed) root.wallpaperDirs = d
        var rChanged = false
        var r = root.wallpaperRecursive.map(p => {
            var e = root.expandHome(p)
            if (e !== p) rChanged = true
            return e
        })
        if (rChanged) root.wallpaperRecursive = r
        faceProbe.running = true
        bannerProbe.running = true
    }

    function isRecursive(path) {
        return root.wallpaperRecursive.indexOf(path) !== -1
    }

    function setRecursive(path, on) {
        var r = root.wallpaperRecursive.slice()
        var i = r.indexOf(path)
        if (on && i === -1) r.push(path)
        if (!on && i !== -1) r.splice(i, 1)
        root.wallpaperRecursive = r
    }


    // ── Bar layout model ────────────────────────────────────────────────────
    // Each section is an ordered list of module keys from barModuleCatalog.
    property var barLayout: {
        "left": ["launcher", "wallpaper", "workspaces", "weather", "temp"],
        "center": ["clock"],
        "right": ["stats", "storage", "memory", "cpu", "battery", "audio", "network", "media", "controlcenter", "todo", "notifications", "screenshot", "power", "tray"]
    }

    readonly property var barModuleCatalog: [
        { key: "launcher",      name: "App Launcher",  icon: "\u{f0349}" },
        { key: "wallpaper",     name: "Wallpaper",     icon: "\u{f021d}" },
        { key: "workspaces",    name: "Workspaces",    icon: "\u{f00f8}" },
        { key: "weather",       name: "Weather",       icon: "\u{f0591}" },
        { key: "temp",          name: "Temperature",   icon: "\u{f0214}" },
        { key: "stats",         name: "Stats Widget",  icon: "󰻠" },
        { key: "storage",       name: "Storage",       icon: "󰋊" },
        { key: "memory",        name: "Memory",        icon: "󰍛" },
        { key: "cpu",           name: "CPU Info",      icon: "󰻠" },
        { key: "battery",       name: "Battery Info",  icon: "󰁹" },
        { key: "audio",         name: "Audio",         icon: "\u{f054d}" },
        { key: "network",       name: "Network Info",  icon: "󰖩" },
        { key: "media",         name: "Media Player",  icon: "󰝚" },
        { key: "clock",         name: "Clock",         icon: "\u{f0546}" },
        { key: "controlcenter", name: "Control Center", icon: "󰒓" },
        { key: "todo",          name: "Todo",           icon: "󰄲" },
        { key: "notifications", name: "Notifications",  icon: "󰂚" },
        { key: "screenshot",    name: "Screenshot",     icon: "\udb80\udd00" },
        { key: "power",         name: "Power Menu",     icon: "\u{f0425}" },
        { key: "tray",          name: "System Tray",    icon: "\u{f0bea}" }
    ]

    function moduleMeta(key) {
        for (var i = 0; i < root.barModuleCatalog.length; i++)
            if (root.barModuleCatalog[i].key === key) return root.barModuleCatalog[i]
        return { key: key, name: key, icon: "·" }
    }

    // Move a module from wherever it is into toSection at toIndex. The UI
    // passes the target chip's index (drop-to-slot semantics): remove first,
    // then insert at that index, clamped to the target's length.
    function moveBarModule(key, toSection, toIndex) {
        var layout = JSON.parse(JSON.stringify(root.barLayout))
        var fromSection = null
        var sections = ["left", "center", "right"]
        for (var i = 0; i < sections.length; i++) {
            if (layout[sections[i]].indexOf(key) >= 0) { fromSection = sections[i]; break }
        }
        if (fromSection === null || !layout[toSection]) return
        layout[fromSection].splice(layout[fromSection].indexOf(key), 1)
        toIndex = Math.max(0, Math.min(toIndex, layout[toSection].length))
        layout[toSection].splice(toIndex, 0, key)
        root.barLayout = layout
        root.save()
    }

    function isModuleVisible(key) {
        switch (key) {
            case "workspaces": return root.showWorkspaces
            case "weather":    return root.showWeather
            case "temp":       return root.showTemp
            case "stats":      return root.showStats
            case "storage":    return root.showStorage
            case "memory":     return root.showMemory
            case "cpu":        return root.showCpu
            case "battery":    return root.showBattery
            case "network":    return root.showNetwork
            case "media":      return root.showMedia
            default: return true
        }
    }

    function toggleModuleVisible(key) {
        switch (key) {
            case "workspaces": root.showWorkspaces = !root.showWorkspaces; break
            case "weather":    root.showWeather = !root.showWeather; break
            case "temp":       root.showTemp = !root.showTemp; break
            case "stats":      root.showStats = !root.showStats; break
            case "storage":    root.showStorage = !root.showStorage; break
            case "memory":     root.showMemory = !root.showMemory; break
            case "cpu":        root.showCpu = !root.showCpu; break
            case "battery":    root.showBattery = !root.showBattery; break
            case "network":    root.showNetwork = !root.showNetwork; break
            case "media":      root.showMedia = !root.showMedia; break
            default: break
        }
    }

    property bool editorDragging: false  // true while a bar-layout chip is being dragged

    // Load Settings
    Process {
        id: loadSettings
        command: ["bash", "-c", "cat ~/.config/quickshell/settings.json 2>/dev/null || echo '{}'"]
        running: true
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var obj = JSON.parse(data.trim());
                    if (obj.showBattery !== undefined) root.showBattery = obj.showBattery;
                    else root.showBattery = root.hasBattery; // fallback to battery detection if not configured

                    if (obj.showCpu !== undefined) root.showCpu = obj.showCpu;
                    if (obj.showMemory !== undefined) root.showMemory = obj.showMemory;
                    if (obj.showStorage !== undefined) root.showStorage = obj.showStorage;
                    if (obj.showTemp !== undefined) root.showTemp = obj.showTemp;
                    if (obj.showNetwork !== undefined) root.showNetwork = obj.showNetwork;
                    if (obj.showMedia !== undefined) root.showMedia = obj.showMedia;
                    if (obj.showWeather !== undefined) root.showWeather = obj.showWeather;
                    if (obj.showWorkspaces !== undefined) root.showWorkspaces = obj.showWorkspaces;
                    if (obj.showStats !== undefined) root.showStats = obj.showStats;
                    if (obj.showGlanceCpu !== undefined) root.showGlanceCpu = obj.showGlanceCpu;
                    if (obj.showGlanceMemory !== undefined) root.showGlanceMemory = obj.showGlanceMemory;
                    if (obj.showGlanceStorage !== undefined) root.showGlanceStorage = obj.showGlanceStorage;
                    if (obj.showGlanceTemp !== undefined) root.showGlanceTemp = obj.showGlanceTemp;
                    if (obj.showGlanceBattery !== undefined) root.showGlanceBattery = obj.showGlanceBattery;
                    if (obj.showGlanceNetwork !== undefined) root.showGlanceNetwork = obj.showGlanceNetwork;
                    if (obj.wallpaperDirs !== undefined && obj.wallpaperDirs.length > 0) root.wallpaperDirs = obj.wallpaperDirs;
                    else if (obj.wallpaperDir !== undefined) root.wallpaperDirs = [obj.wallpaperDir];  // migrate old key
                    if (obj.wallpaperRecursive !== undefined && Array.isArray(obj.wallpaperRecursive)) root.wallpaperRecursive = obj.wallpaperRecursive;
                    if (obj.wallpaperView !== undefined) root.wallpaperView = obj.wallpaperView;
                    if (obj.dashboardPosition !== undefined) root.dashboardPosition = obj.dashboardPosition;
                    if (obj.theme !== undefined) root.theme = obj.theme;
                    if (obj.dynamicTheme !== undefined) root.dynamicTheme = obj.dynamicTheme;
                    if (obj.dynamicWallpaper !== undefined) root.dynamicWallpaper = obj.dynamicWallpaper;
                    if (obj.profileImage !== undefined) root.profileImage = obj.profileImage;
                    if (obj.profileBanner !== undefined) root.profileBanner = obj.profileBanner;
                    if (obj.barLayout && obj.barLayout.left && obj.barLayout.center && obj.barLayout.right) root.barLayout = obj.barLayout;
                } catch (e) {
                    console.log("Error loading quickshell settings: " + e);
                }
                root.loadedFromConfig = true;
                root.loadFavorites()
                root.wallpaperDirs = root.wallpaperDirs.map(p => root.expandHome(p))
                root.wallpaperRecursive = root.wallpaperRecursive.map(p => root.expandHome(p))
                faceProbe.running = true
                bannerProbe.running = true
                if (obj && obj.theme === "dynamic" && root.dynamicWallpaper) root.applyDynamicTheme(root.dynamicWallpaper)
            }
        }
    }

    // Save Settings
    function save() {
        if (!root.loadedFromConfig) return; // don't overwrite with default settings during initial load
        saveProc.running = false;
        var obj = {
            "showBattery": root.showBattery,
            "showCpu": root.showCpu,
            "showMemory": root.showMemory,
            "showStorage": root.showStorage,
            "showTemp": root.showTemp,
            "showNetwork": root.showNetwork,
            "showMedia": root.showMedia,
            "showWeather": root.showWeather,
            "showWorkspaces": root.showWorkspaces,
            "showStats": root.showStats,
            "showGlanceCpu": root.showGlanceCpu,
            "showGlanceMemory": root.showGlanceMemory,
            "showGlanceStorage": root.showGlanceStorage,
            "showGlanceTemp": root.showGlanceTemp,
            "showGlanceBattery": root.showGlanceBattery,
            "showGlanceNetwork": root.showGlanceNetwork,
            "wallpaperDirs": root.wallpaperDirs.map(p => root.toPortable(p)),
            "wallpaperRecursive": root.wallpaperRecursive.map(p => root.toPortable(p)),
            "wallpaperView": root.wallpaperView,
            "dashboardPosition": root.dashboardPosition,
            "theme": root.theme,
            "dynamicTheme": root.dynamicTheme,
            "dynamicWallpaper": root.toPortable(root.dynamicWallpaper),
            "profileImage": root.profileImage,
            "profileBanner": root.profileBanner,
            "barLayout": root.barLayout
        };
        var json = JSON.stringify(obj);
        saveProc.command = [
            "bash", "-c",
            "mkdir -p ~/.config/quickshell && printf '%s' " +
            JSON.stringify(json).replace(/'/g, "'\\''") +
            " > ~/.config/quickshell/settings.json"
        ];
        saveProc.running = true;
    }

    Process {
        id: saveProc
        running: false
    }

    // ── Wallpaper favorites (curated list → ~/.config/quickshell/wallpapers.txt) ──
    function loadFavorites() {
        favLoadProc.running = true
    }

    function saveFavorites() {
        favSaveProc.running = false
        var json = JSON.stringify(root.favorites)
        favSaveProc.command = [
            "bash", "-c",
            "mkdir -p ~/.config/quickshell && printf '%s' " +
            JSON.stringify(json).replace(/'/g, "'\\''") +
            " > ~/.config/quickshell/wallpapers.txt"
        ]
        favSaveProc.running = true
    }

    function favorite(path) {
        if (root.favorites.indexOf(path) === -1) {
            var f = root.favorites.slice()
            f.push(path)
            root.favorites = f
        }
        root.saveFavorites()
    }

    function unfavorite(path) {
        var idx = root.favorites.indexOf(path)
        if (idx !== -1) {
            var f = root.favorites.slice()
            f.splice(idx, 1)
            root.favorites = f
        }
        root.saveFavorites()
    }

    function isFavorite(path) {
        return root.favorites.indexOf(path) !== -1
    }

    Process {
        id: favLoadProc
        command: ["bash", "-c", "cat ~/.config/quickshell/wallpapers.txt 2>/dev/null || echo '[]'"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var arr = JSON.parse(data.trim())
                    if (Array.isArray(arr)) {
                        root.favorites = arr
                        return
                    }
                } catch (e) { }
                // Legacy format: one path per line (old scan cache).
                var lines = data.trim().split("\n")
                var out = []
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i].trim()
                    if (l !== "" && l[0] !== "#") out.push(l)
                }
                root.favorites = out
                root.saveFavorites()
            }
        }
    }

    Process {
        id: favSaveProc
        running: false
    }

    // Battery Auto-Detection
    Process {
        id: detectBatteryProc
        command: ["bash", "-c", "ls -d /sys/class/power_supply/BAT* 2>/dev/null | wc -l"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var count = parseInt(data.trim())
                root.hasBattery = (!isNaN(count) && count > 0)
                // If config hasn't set showBattery yet, use battery presence as the default
                if (!root.loadedFromConfig) {
                    root.showBattery = root.hasBattery;
                }
            }
        }
    }

    // Save triggers on changes
    onShowBatteryChanged: save()
    onShowCpuChanged: save()
    onShowMemoryChanged: save()
    onShowStorageChanged: save()
    onShowTempChanged: save()
    onShowNetworkChanged: save()
    onShowMediaChanged: save()
    onShowWeatherChanged: save()
    onShowWorkspacesChanged: save()
    onShowStatsChanged: save()
    onShowGlanceCpuChanged: save()
    onShowGlanceMemoryChanged: save()
    onShowGlanceStorageChanged: save()
    onShowGlanceTempChanged: save()
    onShowGlanceBatteryChanged: save()
    onShowGlanceNetworkChanged: save()
    onWallpaperDirsChanged: save()
    onWallpaperRecursiveChanged: save()
    onWallpaperViewChanged: save()
    onDashboardPositionChanged: save()
    onBarLayoutChanged: save()
    onDynamicThemeChanged: save()
    onDynamicWallpaperChanged: save()
    onProfileImageChanged: save()
    onProfileBannerChanged: save()
    onThemeChanged: {
        Theme.currentTheme = root.theme
        save()
    }

    // Cycle to the next theme in Theme.themeNames (wraps around).
    function cycleTheme() {
        var names = Theme.themeNames
        var idx = names.indexOf(root.theme)
        root.theme = names[(idx + 1) % names.length]
    }

    // ── Wallpaper color-match theme ──────────────────────────────────────
    // Runs qs-theme.py on a wallpaper and applies the resulting palette to
    // Theme. Also remembers the path so the theme can be re-derived at boot.
    function applyDynamicTheme(path) {
        if (!path || path === "") return
        root.dynamicWallpaper = path
        // bash -c expands `~` (Process runs args without a shell).
        themeGenProc.command = ["bash", "-c", "python3 -u ~/.scripts/qs-theme.py " + JSON.stringify(path)]
        themeGenProc.running = true
    }

    Process {
        id: themeGenProc
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var obj = JSON.parse(data.trim())
                    if (obj.fallback) {
                        Theme.clearDynamicPalette()
                        return
                    }
                    if (Theme.applyDynamicPalette(obj.palette)) {
                        root.theme = "dynamic"
                    }
                } catch (e) {
                    console.log("qs-theme parse error: " + e)
                    Theme.clearDynamicPalette()
                }
            }
        }
    }

    // Wallpaper browsing is handled by WallpaperPicker (live dir listing);
    // the old "scan" cache no longer exists.
}
