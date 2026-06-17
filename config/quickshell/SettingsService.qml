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
    property string wallpaperDir: "~/Pictures/wallpapers"

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
                    if (obj.wallpaperDir !== undefined) root.wallpaperDir = obj.wallpaperDir;
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
            "wallpaperDir": root.wallpaperDir
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
    onWallpaperDirChanged: save()

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
