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
                Text {
                    text: "󰒓  Control Center"
                    color: "#0df0ff"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pointSize: 9
                    font.bold: true
                    Layout.fillWidth: true
                }
                Text {
                    text: "✕"
                    color: "#7984a4"
                    font.pointSize: 9
                    MouseArea { anchors.fill: parent; onClicked: root.visible = false }
                }
            }

            // Divider
            Rectangle { Layout.fillWidth: true; height: 1; color: "#1a5bcefa" }

            // Volume
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: root.muted ? " " : (root.volume < 33 ? " " : (root.volume < 66 ? " " : " "))
                        color: "#fab387"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pointSize: 10
                    }
                    Text {
                        text: "Volume"
                        color: "#c8d2e0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pointSize: 8
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.muted ? "muted" : (root.volume + "%")
                        color: "#fab387"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pointSize: 8
                    }
                    // Mute toggle
                    Rectangle {
                        implicitWidth: 24; implicitHeight: 18; radius: 3
                        color: root.muted ? "#55fab387" : "transparent"
                        border.color: "#55fab387"; border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: root.muted ? "" : ""
                            color: "#fab387"
                            font.family: "JetBrainsMono Nerd Font"
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
                        font.family: "JetBrainsMono Nerd Font"
                        font.pointSize: 10
                    }
                    Text {
                        text: "Brightness"
                        color: "#c8d2e0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pointSize: 8
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.brightness + "%"
                        color: "#ffcc00"
                        font.family: "JetBrainsMono Nerd Font"
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
                        { icon: "", label: "WiFi",      cmd: ["nm-connection-editor"] },
                        { icon: "󰂯", label: "Bluetooth", cmd: ["blueman-manager"] },
                        { icon: "", label: "Night",     cmd: ["bash", "-c", "gammastep -O 4500 &"] },
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
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: 12
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.label
                                color: "#7984a4"
                                font.family: "JetBrainsMono Nerd Font"
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
    }
}
