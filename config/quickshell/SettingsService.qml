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

    property string wallpaperDir: "~/Pictures/wallpapers"
    property string dashboardPosition: "right"  // "left", "center", "right"
    property string theme: "default"  // key into Theme.palettes (Theme.applyTheme via onThemeChanged)

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
                    if (obj.wallpaperDir !== undefined) root.wallpaperDir = obj.wallpaperDir;
                    if (obj.dashboardPosition !== undefined) root.dashboardPosition = obj.dashboardPosition;
                    if (obj.theme !== undefined) root.theme = obj.theme;
                    if (obj.barLayout && obj.barLayout.left && obj.barLayout.center && obj.barLayout.right) root.barLayout = obj.barLayout;
                } catch (e) {
                    console.log("Error loading quickshell settings: " + e);
                }
                root.loadedFromConfig = true;
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
            "wallpaperDir": root.wallpaperDir,
            "dashboardPosition": root.dashboardPosition,
            "theme": root.theme,
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
    onWallpaperDirChanged: save()
    onDashboardPositionChanged: save()
    onBarLayoutChanged: save()
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

    // Scan Wallpaper Folder command
    signal scanFinished(bool success, string message)

    function scanWallpapers() {
        scanProc.running = false;
        // Expand ~ to $HOME
        var dir = root.wallpaperDir.replace(/^~/, "$HOME");
        // We will find png, jpg, jpeg, webp, gif files, and write them to ~/.config/quickshell/wallpapers.txt
        var script = "mkdir -p ~/.config/quickshell && find \"" + dir + "\" -type f \\( -iname \"*.png\" -o -iname \"*.jpg\" -o -iname \"*.jpeg\" -o -iname \"*.webp\" -o -iname \"*.gif\" \\) | sort > ~/.config/quickshell/wallpapers.txt";
        scanProc.command = ["bash", "-c", script];
        scanProc.running = true;
    }

    Process {
        id: scanProc
        running: false
        onRunningChanged: {
            if (!running) {
                // If it finished, check if the wallpapers.txt has any content
                checkProc.running = true;
            }
        }
    }

    Process {
        id: checkProc
        command: ["bash", "-c", "wc -l < ~/.config/quickshell/wallpapers.txt 2>/dev/null || echo 0"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                var count = parseInt(data.trim());
                if (!isNaN(count) && count > 0) {
                    root.scanFinished(true, "Found " + count + " wallpapers");
                } else {
                    root.scanFinished(false, "No wallpapers found in " + root.wallpaperDir);
                }
            }
        }
    }
}
