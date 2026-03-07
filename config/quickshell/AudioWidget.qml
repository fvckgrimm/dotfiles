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
        if (muted || volume === 0) return " "
        if (volume < 33)           return " "
        if (volume < 66)           return " "
        return " "
    }

    Process {
        id: volProc
        command: ["bash", "-c",
            "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                // Output format: "Volume: 0.87" or "Volume: 0.87 [MUTED]"
                root.muted  = data.includes("[MUTED]")
                var match   = data.match(/[\d.]+/)
                if (match) root.volume = Math.round(parseFloat(match[0]) * 100)
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: volProc.running = true
    }

    StatChip {
        id: chip
        anchors.fill: parent
        icon: root.volIcon
        value: root.muted ? "muted" : (root.volume + "%")
        iconColor: "#fab387"
        valueColor: "#fab387"
        accentColor: "#80fab387"
        bgColor: "#661e1e28"
        tooltipText: "Volume: " + root.volume + "%" + (root.muted ? " [MUTED]" : "")

        onClicked: Quickshell.exec(["pavucontrol"])
        onRightClicked: Quickshell.exec(["bash", "-c", "amixer sset Master toggle 1>/dev/null"])
    }

    // Scroll to change volume
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                Quickshell.exec(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "0.03+"])
            else
                Quickshell.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "0.03-"])
            // refresh immediately
            volProc.running = true
        }
    }
}
