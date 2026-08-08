import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: bar
    required property var screen

    visible: IpcBridge.barVisible

    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top

    anchors { top: true; left: true; right: true }
    margins { left: Theme.spacingMd; right: Theme.spacingMd; top: Theme.spacingMd }
    implicitHeight: 34
    color: "transparent"
    exclusiveZone: implicitHeight + Theme.spacingMd

    NotificationPopup { id: notifPopup; barWindow: bar }

    // Unified Notifications / Calendar / Controls panel — all three bar
    // triggers below open this same popup, just landing on a different tab.
    Dashboard {
        id: dashboard
        visible: false
        property string position: SettingsService.dashboardPosition
        anchor.window: bar
        anchor.rect.x: (position === "left") ? 12 : (position === "center") ? (bar.width - implicitWidth) / 2 : bar.width - implicitWidth - 12
        anchor.rect.y: bar.implicitHeight
        anchor.rect.width: 1
        anchor.rect.height: 1
    }

    function toggleDashboard(t) {
        if (dashboard.visible && dashboard.tab === t) dashboard.visible = false
        else dashboard.openTab(t)
    }

    WallpaperPicker {
        id: wallpaperPicker
        barWindow: bar
        visible: false
    }

    Connections {
        target: WallpaperService
        function onOpenChanged() {
            if (WallpaperService.open) wallpaperPicker.open()
            else wallpaperPicker.close(false)
        }
    }

    Connections {
        target: wallpaperPicker
        function onVisibleChanged() {
            if (!wallpaperPicker.visible) WallpaperService.open = false
        }
    }

    // ── IPC hooks for keybinds — see shell.qml for the IpcHandler targets ──
    Connections {
        target: IpcBridge
        function onToggleNotifCenter()   { bar.toggleDashboard("notifs") }
        function onToggleCalendar()      { bar.toggleDashboard("calendar") }
        function onToggleControlCenter() { bar.toggleDashboard("home") }
    }

    // ── Bar surface ──────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Theme.bgBar
        radius: Theme.radiusXl
        clip: true

        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: Theme.radiusXl; rightMargin: Theme.radiusXl }
            height: 1
            color: Theme.outlineVariant
        }

        Item {
            id: host
            anchors.fill: parent
            anchors.margins: Theme.spacingXs

            // ── Module catalog — every bar module is a self-contained component ──
            Component { id: compLauncher; BarButton {
                text: "\u{f0349}"
                textColor: Theme.primary
                borderColor: LauncherService.open ? Theme.primary : "transparent"
                tooltipText: "App Launcher (Super+Space)"
                onClicked: LauncherService.toggle()
                onRightClicked: Quickshell.execDetached(Theme.drawerCmd)
            } }

            Component { id: compWallpaper; BarButton {
                text: "\u{f021d}"
                textColor: Theme.tertiary
                borderColor: WallpaperService.open ? Theme.tertiary : "transparent"
                tooltipText: "Wallpaper Picker (Super+Shift+W)"
                onClicked: WallpaperService.toggle()
            } }

            Component { id: compWorkspaces; WorkspacesWidget { visible: SettingsService.showWorkspaces } }
            Component { id: compWeather;    WeatherWidget { visible: SettingsService.showWeather } }
            Component { id: compTemp;       TempWidget { visible: SettingsService.showTemp } }

            Component { id: compStats; StatsWidget {
                visible: SettingsService.showStats
                onClicked: bar.toggleDashboard("stats")
            } }
            Component { id: compStorage; StorageWidget { visible: SettingsService.showStorage } }
            Component { id: compMemory;  MemoryWidget { visible: SettingsService.showMemory } }
            Component { id: compCpu;     CpuWidget { visible: SettingsService.showCpu } }
            Component { id: compBattery; BatteryWidget { visible: SettingsService.showBattery } }
            Component { id: compAudio;   AudioWidget { } }
            Component { id: compNetwork; NetworkWidget { visible: SettingsService.showNetwork } }
            Component { id: compMedia;   MediaWidget { barWindow: bar; visible: SettingsService.showMedia } }

            Component { id: compClock; ClockWidget { onClockClicked: bar.toggleDashboard("calendar") } }

            Component { id: compControlCenter; BarButton {
                text: "󰒓"
                textColor: (dashboard.visible && dashboard.tab === "home") ? Theme.primary : Theme.surfaceTextVariant
                borderColor: (dashboard.visible && dashboard.tab === "home") ? Theme.primary : "transparent"
                tooltipText: "Control Center"
                onClicked: bar.toggleDashboard("home")
            } }

            Component { id: compTodo; BarButton {
                readonly property int pending: TodoService.pendingToday
                text: pending > 0 ? ("󰄲 " + pending) : "󰄲"
                textColor: pending > 0 ? Theme.secondary : Theme.surfaceTextVariant
                borderColor: TodoService.open ? Theme.secondary : "transparent"
                tooltipText: pending > 0
                    ? (pending + " task" + (pending > 1 ? "s" : "") + " remaining")
                    : "Todo  (Super+T)"
                onClicked: TodoService.toggle()
            } }

            Component { id: compNotifs; BarButton {
                readonly property int count: NotificationService.unreadCount ?? 0
                text: count > 0 ? ("󰂚 " + count) : "󰂜"
                textColor: count > 0 ? Theme.warning : Theme.surfaceTextVariant
                borderColor: (dashboard.visible && dashboard.tab === "notifs") ? Theme.warning
                           : (count > 0 ? Theme.warning : "transparent")
                tooltipText: count > 0
                    ? (count + " notification" + (count > 1 ? "s" : ""))
                    : "No notifications"
                onClicked: bar.toggleDashboard("notifs")
            } }

            Component { id: compScreenshot; BarButton {
                text: "\udb80\udd00"
                textColor: Theme.error
                borderColor: "transparent"
                onClicked: Hyprland.dispatch("hl.plugin.hyprcapture.open('fullscreen')")
                onRightClicked: Hyprland.dispatch("hl.plugin.hyprcapture.open('region')")
                tooltipText: "Screenshot"
            } }

            Component { id: compPower; BarButton {
                text: "\u{f0425}"
                textColor: Theme.error
                borderColor: "transparent"
                onClicked: Quickshell.execDetached(["wlogout"])
                tooltipText: "Power Menu"
            } }

            Component { id: compTray; TrayWidget { barWindow: bar } }

            function compFor(key) {
                switch (key) {
                    case "launcher": return compLauncher
                    case "wallpaper": return compWallpaper
                    case "workspaces": return compWorkspaces
                    case "weather": return compWeather
                    case "temp": return compTemp
                    case "stats": return compStats
                    case "storage": return compStorage
                    case "memory": return compMemory
                    case "cpu": return compCpu
                    case "battery": return compBattery
                    case "audio": return compAudio
                    case "network": return compNetwork
                    case "media": return compMedia
                    case "clock": return compClock
                    case "controlcenter": return compControlCenter
                    case "todo": return compTodo
                    case "notifications": return compNotifs
                    case "screenshot": return compScreenshot
                    case "power": return compPower
                    case "tray": return compTray
                }
                return null
            }

            // ── LEFT ──────────────────────────────────────────────────────
            RowLayout {
                id: leftItems
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.spacingSm }
                spacing: Theme.spacingXs

                Repeater {
                    model: SettingsService.barLayout.left
                    delegate: Item {
                        required property var modelData
                        visible: SettingsService.isModuleVisible(modelData)
                        implicitHeight: loader.implicitHeight
                        implicitWidth: loader.implicitWidth

                        Loader {
                            id: loader
                            sourceComponent: host.compFor(modelData)
                        }
                    }
                }
            }

            // ── CENTER ────────────────────────────────────────────────────
            RowLayout {
                id: centerItems
                anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
                spacing: Theme.spacingXs

                Repeater {
                    model: SettingsService.barLayout.center
                    delegate: Item {
                        required property var modelData
                        visible: SettingsService.isModuleVisible(modelData)
                        implicitHeight: loader.implicitHeight
                        implicitWidth: loader.implicitWidth

                        Loader {
                            id: loader
                            sourceComponent: host.compFor(modelData)
                        }
                    }
                }
            }

            // ── RIGHT ─────────────────────────────────────────────────────
            RowLayout {
                id: rightItems
                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: Theme.spacingSm }
                spacing: Theme.spacingXs

                Repeater {
                    model: SettingsService.barLayout.right
                    delegate: Item {
                        required property var modelData
                        visible: SettingsService.isModuleVisible(modelData)
                        implicitHeight: loader.implicitHeight
                        implicitWidth: loader.implicitWidth

                        Loader {
                            id: loader
                            sourceComponent: host.compFor(modelData)
                        }
                    }
                }
            }
        }
    }
}
