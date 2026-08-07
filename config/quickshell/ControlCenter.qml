import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Control center popup — volume, brightness, quick toggles
PopupWindow {
    id: root
    implicitWidth: 300
    implicitHeight: mainCol.implicitHeight + Theme.spacingXl * 2
    color: "transparent"

    property int volume: 0
    property bool muted: false
    property int brightness: 100
    property bool showSettings: false

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

    // MPRIS position doesn't update reactively on its own — re-read it
    // periodically while the card is visible (see MediaService.poll).
    Timer {
        interval: 500
        repeat: true
        running: root.visible && MediaService.hasPlayer
        onTriggered: MediaService.poll()
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.spacingXs
        radius: Theme.radiusXl
        color: Theme.cardColor()
        border.color: Theme.cardBorder()
        border.width: 1

        ColumnLayout {
            id: mainCol
            anchors { fill: parent; margins: Theme.spacingXl }
            spacing: Theme.spacingLg

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingMd
                Text {
                    text: root.showSettings ? "󰒓  Settings" : "󰒓  Control Center"
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.bodyLarge
                    font.bold: true
                    Layout.fillWidth: true
                }
                Rectangle {
                    implicitWidth: 20; implicitHeight: 20; radius: Theme.radiusSm
                    color: gearMa.containsMouse ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: root.showSettings ? "󰅖" : "󰒓"
                        color: Theme.surfaceTextVariant
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.titleSmall
                    }
                    MouseArea { id: gearMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.showSettings = !root.showSettings }
                }
                Rectangle {
                    implicitWidth: 20; implicitHeight: 20; radius: Theme.radiusSm
                    color: closeMa.containsMouse ? Theme.withAlpha(Theme.error, 0.16) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeMa.containsMouse ? Theme.error : Theme.surfaceTextVariant
                        font.pointSize: Theme.labelLarge
                    }
                    MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.visible = false }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outlineVariant }

            // CONTROLS VIEW
            ColumnLayout {
                id: controlsView
                Layout.fillWidth: true
                visible: !root.showSettings
                spacing: Theme.spacingLg

                // ── NOW PLAYING ───────────────────────────────────────────
                ColumnLayout {
                    id: nowPlayingCard
                    Layout.fillWidth: true
                    visible: MediaService.hasPlayer
                    spacing: Theme.spacingSm

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingMd

                        Rectangle {
                            Layout.preferredWidth: 56
                            Layout.preferredHeight: 56
                            radius: Theme.radiusMd
                            clip: true
                            color: Theme.surfaceContainerHigh

                            Image {
                                anchors.fill: parent
                                source: MediaService.artUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                visible: MediaService.artUrl !== ""
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "\u{f001}"
                                color: Theme.tertiary
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.titleMedium
                                visible: MediaService.artUrl === ""
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingXs

                            Text {
                                Layout.fillWidth: true
                                text: MediaService.title || MediaService.identity
                                color: Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.bodyMedium
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: (MediaService.artist + (MediaService.album ? " · " + MediaService.album : "")).trim()
                                color: Theme.surfaceTextVariant
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.labelMedium
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: MediaService.identity
                                color: Theme.surfaceTextDim
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.labelSmall
                                elide: Text.ElideRight
                            }
                        }

                        ColumnLayout {
                            spacing: Theme.spacingXs
                            RowLayout {
                                spacing: Theme.spacingXs
                                MediaIconButton {
                                    size: 26
                                    glyph: "\u{f048}"  // fa step-backward
                                    tooltipText: "Previous"
                                    onClicked: MediaService.previous()
                                }
                                MediaIconButton {
                                    size: 30
                                    glyph: MediaService.isPlaying ? "\u{f04c}" : "\u{f04b}"  // fa pause/play
                                    tooltipText: MediaService.isPlaying ? "Pause" : "Play"
                                    onClicked: MediaService.toggle()
                                }
                                MediaIconButton {
                                    size: 26
                                    glyph: "\u{f051}"  // fa step-forward
                                    tooltipText: "Next"
                                    onClicked: MediaService.next()
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSm

                        Text {
                            text: MediaService.format(MediaService.position)
                            color: Theme.surfaceTextVariant
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.labelSmall
                        }

                        // Custom seek bar — value tracks live position, but
                        // while dragging the knob follows the cursor and the
                        // seek fires on release.
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 16
                            property real frac: MediaService.length > 0
                                ? Math.max(0, Math.min(1, MediaService.position / MediaService.length))
                                : 0
                            property real dragFrac: -1
                            property real shown: dragFrac >= 0 ? dragFrac : frac

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                height: 4
                                radius: Theme.radiusFull
                                color: Theme.surfaceContainerHigh
                                anchors.left: parent.left
                                anchors.right: parent.right
                            }
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                height: 4
                                radius: Theme.radiusFull
                                color: Theme.tertiary
                                width: parent.shown * parent.width
                            }
                            Rectangle {
                                x: parent.shown * (parent.width - width)
                                anchors.verticalCenter: parent.verticalCenter
                                width: 12; height: 12; radius: Theme.radiusFull
                                color: Theme.tertiary
                                border.color: Theme.surfaceContainerLowest
                                border.width: 2
                            }
                            MouseArea {
                                anchors.fill: parent
                                onPressed: mouse => { parent.dragFrac = Math.max(0, Math.min(1, mouse.x / width)) }
                                onPositionChanged: mouse => { if (pressed) parent.dragFrac = Math.max(0, Math.min(1, mouse.x / width)) }
                                onReleased: mouse => {
                                    MediaService.seekToFraction(parent.dragFrac)
                                    parent.dragFrac = -1
                                }
                            }
                        }

                        Text {
                            text: MediaService.format(MediaService.length)
                            color: Theme.surfaceTextVariant
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.labelSmall
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.outlineVariant
                    visible: MediaService.hasPlayer
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSm

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: root.muted ? "\u{f0581} " : (root.volume < 33 ? "\u{f057f} " : (root.volume < 66 ? "\u{f0580} " : "\u{f057e} "))
                            color: Theme.secondary
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.titleSmall
                        }
                        Text {
                            text: "Volume"; color: Theme.surfaceText
                            font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                            Layout.fillWidth: true
                        }
                        Text {
                            text: root.muted ? "muted" : (root.volume + "%")
                            color: Theme.secondary; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                        }
                        Rectangle {
                            implicitWidth: 24; implicitHeight: 20; radius: Theme.radiusSm
                            color: root.muted ? Theme.withAlpha(Theme.secondary, 0.2) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: root.muted ? "\u{f0581}" : "\u{f057e}"
                                color: Theme.secondary
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.labelLarge
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

                    SliderBar {
                        Layout.fillWidth: true
                        value: root.muted ? 0 : root.volume
                        accentColor: Theme.secondary
                        onMoved: v => {
                            root.volume = v
                            Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0",
                                "@DEFAULT_AUDIO_SINK@", (v / 100).toFixed(2)])
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSm

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "󰃞"; color: Theme.warning; font.family: Theme.fontFamily; font.pointSize: Theme.titleSmall }
                        Text {
                            text: "Brightness"; color: Theme.surfaceText
                            font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                            Layout.fillWidth: true
                        }
                        Text { text: root.brightness + "%"; color: Theme.warning; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge }
                    }

                    SliderBar {
                        Layout.fillWidth: true
                        value: root.brightness
                        accentColor: Theme.warning
                        onMoved: v => {
                            root.brightness = v
                            Quickshell.execDetached(["brightnessctl", "set", v + "%"])
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outlineVariant }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingMd

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
                            implicitHeight: 48
                            radius: Theme.radiusMd
                            color: btnMa.containsMouse ? Theme.withAlpha(Theme.primary, 0.14) : Theme.surfaceContainerHigh

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: Theme.spacingXs
                                Text { Layout.alignment: Qt.AlignHCenter; text: modelData.icon; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pointSize: Theme.titleMedium }
                                Text { Layout.alignment: Qt.AlignHCenter; text: modelData.label; color: Theme.surfaceTextVariant; font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall }
                            }

                            MouseArea { id: btnMa; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(modelData.cmd) }
                        }
                    }
                }
            }

            // SETTINGS VIEW
            ColumnLayout {
                id: settingsView
                Layout.fillWidth: true
                visible: root.showSettings
                spacing: Theme.spacingMd

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
                    else if (key === "stats") SettingsService.showStats = !SettingsService.showStats
                }

                Text { text: "MODULE VISIBILITY"; color: Theme.surfaceTextVariant; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; font.bold: true }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSm

                    // Drag-and-drop bar layout editor (click chips to toggle visibility)
                    BarLayoutEditor { Layout.fillWidth: true }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outlineVariant }

                Text { text: "THEME"; color: Theme.surfaceTextVariant; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; font.bold: true }

                Text { text: "Active: " + Theme.prettyName(SettingsService.theme); color: Theme.surfaceTextVariant; font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall }

                ThemePicker { Layout.fillWidth: true }

                Text { text: "WALLPAPERS SOURCE"; color: Theme.surfaceTextVariant; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; font.bold: true }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSm

                    Text { text: "Directory to scan:"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: Theme.radiusSm
                        color: Theme.surfaceContainerLow

                        TextInput {
                            id: dirInput
                            anchors { fill: parent; leftMargin: Theme.spacingMd; rightMargin: Theme.spacingMd; verticalCenter: parent.verticalCenter }
                            text: SettingsService.wallpaperDir
                            color: Theme.surfaceText
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.labelLarge
                            selectByMouse: true
                            verticalAlignment: TextInput.AlignVCenter
                            onTextEdited: SettingsService.wallpaperDir = text
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        radius: Theme.radiusSm
                        color: scanMa.containsMouse ? Theme.withAlpha(Theme.primary, 0.2) : Theme.withAlpha(Theme.primary, 0.12)

                        Text {
                            anchors.centerIn: parent
                            text: "󰚔  Scan & Update list"
                            color: Theme.primary
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.labelLarge
                            font.bold: true
                        }

                        MouseArea {
                            id: scanMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                scanStatusText.text = "Scanning..."
                                scanStatusText.color = Theme.surfaceText
                                SettingsService.scanWallpapers()
                            }
                        }
                    }

                    Text {
                        id: scanStatusText
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: ""
                        color: Theme.surfaceTextVariant
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.labelLarge
                    }

                    Connections {
                        target: SettingsService
                        function onScanFinished(success, message) {
                            scanStatusText.text = message
                            scanStatusText.color = success ? Theme.success : Theme.error
                        }
                    }
                }
            }
        }
    }
}
