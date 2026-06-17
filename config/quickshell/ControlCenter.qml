import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Control center popup — volume, brightness, quick toggles
PopupWindow {
    id: root
    implicitWidth: 300
    implicitHeight: mainCol.implicitHeight + 24
    color: "transparent"

    // State
    property int volume: 0
    property bool muted: false
    property int brightness: 100
    property bool showSettings: false

    // Poll volume
    Process {
        id: volPoll
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.muted = data.includes("[MUTED]")
                var m = data.match(/[\d.]+/)
                if (m) root.volume = Math.round(parseFloat(m[0]) * 100)
            }
        }
    }

    // Poll brightness
    Process {
        id: brightPoll
        command: ["bash", "-c", "brightnessctl get 2>/dev/null; brightnessctl max 2>/dev/null"]
        running: true
        property int cur: 0
        property int max: 100
        property int lineNum: 0
        stdout: SplitParser {
            onRead: data => {
                var v = parseInt(data.trim())
                if (!isNaN(v)) {
                    if (brightPoll.lineNum === 0) brightPoll.cur = v
                    else root.brightness = Math.round((brightPoll.cur / v) * 100)
                    brightPoll.lineNum++
                }
            }
        }
        onRunningChanged: if (running) lineNum = 0
    }

    onVisibleChanged: {
        if (visible) { volPoll.running = true; brightPoll.running = true }
        else { showSettings = false }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: 8
        color: "#f00d1117"
        border.color: "#335bcefa"
        border.width: 1

        ColumnLayout {
            id: mainCol
            anchors { fill: parent; margins: 16 }
            spacing: 14

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: root.showSettings ? "󰒓  Settings" : "󰒓  Control Center"
                    color: "#0df0ff"
                    font.family: Theme.fontFamily
                    font.pointSize: 9
                    font.bold: true
                    Layout.fillWidth: true
                }
                // Gear/Settings Toggle Button
                Rectangle {
                    implicitWidth: 16; implicitHeight: 16
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: root.showSettings ? "󰅖" : "󰒓"
                        color: gearMa.containsMouse ? "#0df0ff" : "#7984a4"
                        font.family: Theme.fontFamily
                        font.pointSize: 10
                    }
                    MouseArea {
                        id: gearMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.showSettings = !root.showSettings
                    }
                }
                Text {
                    text: "✕"
                    color: closeMa.containsMouse ? "#ff416c" : "#7984a4"
                    font.pointSize: 9
                    font.family: Theme.fontFamily
                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.visible = false
                    }
                }
            }

            // Divider
            Rectangle { Layout.fillWidth: true; height: 1; color: "#1a5bcefa" }

            // CONTROLS VIEW
            ColumnLayout {
                id: controlsView
                Layout.fillWidth: true
                visible: !root.showSettings
                spacing: 14

                // Volume
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: root.muted ? "\u{f0581} " : (root.volume < 33 ? "\u{f057f} " : (root.volume < 66 ? "\u{f0580} " : "\u{f057e} "))
                            color: "#fab387"
                            font.family: Theme.fontFamily
                            font.pointSize: 10
                        }
                        Text {
                            text: "Volume"
                            color: "#c8d2e0"
                            font.family: Theme.fontFamily
                            font.pointSize: 8
                            Layout.fillWidth: true
                        }
                        Text {
                            text: root.muted ? "muted" : (root.volume + "%")
                            color: "#fab387"
                            font.family: Theme.fontFamily
                            font.pointSize: 8
                        }
                        // Mute toggle
                        Rectangle {
                            implicitWidth: 24; implicitHeight: 18; radius: 3
                            color: root.muted ? "#55fab387" : "transparent"
                            border.color: "#55fab387"; border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: root.muted ? "\u{f0581}" : "\u{f057e}"
                                color: "#fab387"
                                font.family: Theme.fontFamily
                                font.pointSize: 9
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    Quickshell.execDetached(["bash", "-c", "amixer sset Master toggle 1>/dev/null"])
                                    Qt.callLater(() => volPoll.running = true)
                                }
                            }
                        }
                    }

                    // Volume slider
                    SliderBar {
                        Layout.fillWidth: true
                        value: root.muted ? 0 : root.volume
                        accentColor: "#fab387"
                        onMoved: v => {
                            root.volume = v
                            Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0",
                                "@DEFAULT_AUDIO_SINK@", (v / 100).toFixed(2)])
                        }
                    }
                }

                // Brightness
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰃞"
                            color: "#ffcc00"
                            font.family: Theme.fontFamily
                            font.pointSize: 10
                        }
                        Text {
                            text: "Brightness"
                            color: "#c8d2e0"
                            font.family: Theme.fontFamily
                            font.pointSize: 8
                            Layout.fillWidth: true
                        }
                        Text {
                            text: root.brightness + "%"
                            color: "#ffcc00"
                            font.family: Theme.fontFamily
                            font.pointSize: 8
                        }
                    }

                    SliderBar {
                        Layout.fillWidth: true
                        value: root.brightness
                        accentColor: "#ffcc00"
                        onMoved: v => {
                            root.brightness = v
                            Quickshell.execDetached(["brightnessctl", "set", v + "%"])
                        }
                    }
                }

                // Divider
                Rectangle { Layout.fillWidth: true; height: 1; color: "#1a5bcefa" }

                // Quick action buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { icon: "\u{f05a9}", label: "WiFi",      cmd: ["nm-connection-editor"] },
                            { icon: "󰂯", label: "Bluetooth", cmd: ["blueman-manager"] },
                            { icon: "\u{f0594}", label: "Night",     cmd: ["bash", "-c", "gammastep -O 4500 &"] },
                            { icon: "󰌾", label: "Lock",      cmd: ["hyprlock"] },
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 44
                            radius: 4
                            color: btnMa.containsMouse ? "#1a5bcefa" : "#0d1e1e28"
                            border.color: "#1a5bcefa"
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 3
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.icon
                                    color: "#c8d2e0"
                                    font.family: Theme.fontFamily
                                    font.pointSize: 12
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    color: "#7984a4"
                                    font.family: Theme.fontFamily
                                    font.pointSize: 6
                                }
                            }

                            MouseArea {
                                id: btnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: Quickshell.execDetached(modelData.cmd)
                            }
                        }
                    }
                }
            }

            // SETTINGS VIEW
            ColumnLayout {
                id: settingsView
                Layout.fillWidth: true
                visible: root.showSettings
                spacing: 12

                function toggleSetting(key) {
                    if (key === "workspaces") SettingsService.showWorkspaces = !SettingsService.showWorkspaces
                    else if (key === "weather") SettingsService.showWeather = !SettingsService.showWeather
                    else if (key === "temp") SettingsService.showTemp = !SettingsService.showTemp
                    else if (key === "storage") SettingsService.showStorage = !SettingsService.showStorage
                    else if (key === "memory") SettingsService.showMemory = !SettingsService.showMemory
                    else if (key === "cpu") SettingsService.showCpu = !SettingsService.showCpu
                    else if (key === "battery") SettingsService.showBattery = !SettingsService.showBattery
                    else if (key === "network") SettingsService.showNetwork = !SettingsService.showNetwork
                    else if (key === "media") SettingsService.showMedia = !SettingsService.showMedia
                }

                // Header 1: Module Visibility
                Text {
                    text: "MODULE VISIBILITY"
                    color: "#7984a4"
                    font.family: Theme.fontFamily
                    font.pointSize: 7
                    font.bold: true
                }

                // Grid of modules
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { key: "workspaces", name: "Workspaces", icon: "󰮯" },
                            { key: "weather", name: "Weather", icon: "󰖐" },
                            { key: "temp", name: "Temperature", icon: "󰔏" },
                            { key: "storage", name: "Storage", icon: "󰋊" },
                            { key: "memory", name: "Memory", icon: "󰍛" },
                            { key: "cpu", name: "CPU Info", icon: "󰻠" },
                            { key: "battery", name: "Battery Info", icon: "󰁹", suffix: SettingsService.hasBattery ? " (Detected)" : " (No Battery)" },
                            { key: "network", name: "Network Info", icon: "󰖩" },
                            { key: "media", name: "Media Player", icon: "󰝚" }
                        ]

                        delegate: RowLayout {
                            id: rowItem
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8

                            readonly property bool active: {
                                if (modelData.key === "workspaces") return SettingsService.showWorkspaces
                                if (modelData.key === "weather") return SettingsService.showWeather
                                if (modelData.key === "temp") return SettingsService.showTemp
                                if (modelData.key === "storage") return SettingsService.showStorage
                                if (modelData.key === "memory") return SettingsService.showMemory
                                if (modelData.key === "cpu") return SettingsService.showCpu
                                if (modelData.key === "battery") return SettingsService.showBattery
                                if (modelData.key === "network") return SettingsService.showNetwork
                                if (modelData.key === "media") return SettingsService.showMedia
                                return true
                            }

                            Text {
                                text: modelData.icon
                                color: rowItem.active ? "#0df0ff" : "#7984a4"
                                font.family: Theme.fontFamily
                                font.pointSize: 10
                                Layout.preferredWidth: 16
                            }

                            Text {
                                text: modelData.name + (modelData.suffix !== undefined ? modelData.suffix : "")
                                color: rowItem.active ? "#d8e0f0" : "#7984a4"
                                font.family: Theme.fontFamily
                                font.pointSize: 8
                                Layout.fillWidth: true
                            }

                            // Custom switch toggle
                            Rectangle {
                                width: 28; height: 14; radius: 7
                                color: rowItem.active ? "#330df0ff" : "transparent"
                                border.color: rowItem.active ? "#0df0ff" : "#557984a4"
                                border.width: 1

                                Rectangle {
                                    width: 10; height: 10; radius: 5
                                    x: rowItem.active ? 15 : 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: rowItem.active ? "#0df0ff" : "#7984a4"
                                    Behavior on x { NumberAnimation { duration: 120 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: settingsView.toggleSetting(modelData.key)
                            }
                        }
                    }
                }

                // Divider
                Rectangle { Layout.fillWidth: true; height: 1; color: "#1a5bcefa" }

                // Header 2: Wallpaper Scanning
                Text {
                    text: "WALLPAPERS SOURCE"
                    color: "#7984a4"
                    font.family: Theme.fontFamily
                    font.pointSize: 7
                    font.bold: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "Directory to scan:"
                        color: "#c8d2e0"
                        font.family: Theme.fontFamily
                        font.pointSize: 7
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 24
                        radius: 4
                        color: "#0d1e1e28"
                        border.color: "#1a5bcefa"
                        border.width: 1

                        TextInput {
                            id: dirInput
                            anchors { fill: parent; leftMargin: 8; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            text: SettingsService.wallpaperDir
                            color: "#d8e0f0"
                            font.family: Theme.fontFamily
                            font.pointSize: 8
                            selectByMouse: true
                            verticalAlignment: TextInput.AlignVCenter
                            onTextEdited: SettingsService.wallpaperDir = text
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            height: 26
                            radius: 4
                            color: scanMa.containsMouse ? "#1a5bcefa" : "#0d1e1e28"
                            border.color: "#0df0ff"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "󰚔  Scan & Update list"
                                color: "#0df0ff"
                                font.family: Theme.fontFamily
                                font.pointSize: 8
                                font.bold: true
                            }

                            MouseArea {
                                id: scanMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    scanStatusText.text = "Scanning..."
                                    scanStatusText.color = "#c8d2e0"
                                    SettingsService.scanWallpapers()
                                }
                            }
                        }
                    }

                    Text {
                        id: scanStatusText
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: ""
                        color: "#7984a4"
                        font.family: Theme.fontFamily
                        font.pointSize: 7
                    }

                    Connections {
                        target: SettingsService
                        function onScanFinished(success, message) {
                            scanStatusText.text = message
                            scanStatusText.color = success ? "#00ff9d" : "#ff416c"
                        }
                    }
                }
            }
        }
    }
}
