import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    implicitHeight: 22
    implicitWidth: chip.implicitWidth

    property int volume: 0
    property bool muted: false

    readonly property string volIcon: {
        if (muted || volume === 0) return "\u{f0581} "
        if (volume < 33)           return "\u{f057f} "
        if (volume < 66)           return "\u{f0580} "
        return "\u{f057e} "
    }

    // Poll volume via pamixer to stay in sync with the volume script
    Process {
        id: volProc
        command: ["bash", "-c",
            "echo $(pamixer --get-mute) $(pamixer --get-volume) 2>/dev/null || " +
            "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var s = data.trim()
                // pamixer format: "true 45" or "false 72"
                var pm = s.match(/^(true|false)\s+(\d+)$/)
                if (pm) {
                    root.muted  = pm[1] === "true"
                    root.volume = parseInt(pm[2])
                    return
                }
                // wpctl fallback: "Volume: 0.72 [MUTED]"
                root.muted  = s.includes("[MUTED]")
                var wm = s.match(/[\d.]+/)
                if (wm) root.volume = Math.round(parseFloat(wm[0]) * 100)
            }
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: volProc.running = true
    }

    function volumeUp() {
        Quickshell.execDetached(["bash", "-c", "~/.scripts/volume up"])
        refreshSoon.restart()
    }
    function volumeDown() {
        Quickshell.execDetached(["bash", "-c", "~/.scripts/volume down"])
        refreshSoon.restart()
    }
    function toggleMute() {
        Quickshell.execDetached(["bash", "-c", "~/.scripts/volume mute"])
        refreshSoon.restart()
    }

    // Short delay then repoll so display catches up after the script runs
    Timer {
        id: refreshSoon
        interval: 300
        repeat: false
        onTriggered: volProc.running = true
    }

    StatChip {
        id: chip
        anchors.fill: parent
        icon: root.volIcon
        value: root.muted ? "muted" : (root.volume + "%")
        iconColor: Theme.orange
        valueColor: Theme.orange
        accentColor: "#80fab387"
        bgColor: Theme.bgModule
        tooltipText: "Volume: " + root.volume + "%" + (root.muted ? " [MUTED]" : "") +
                     "\nScroll to adjust · Right-click to mute · Click for mixer"

        onClicked: Quickshell.execDetached(["pavucontrol"])
        onRightClicked: root.toggleMute()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) root.volumeUp()
            else root.volumeDown()
        }
    }
}
