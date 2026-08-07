import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    implicitHeight: 26
    implicitWidth: chip.implicitWidth
    property string avail: "..."
    property int usePct: 0
    property string tooltip: ""
    property string warnClass: ""

    Process {
        id: storProc
        command: ["bash", "-c", "df -h -P -l / | awk 'NR==2{print $4\"|\"$5\"|\"$2\"|\"$3}'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split("|")
                if (parts.length < 4) return
                root.avail = parts[0]
                root.usePct = parseInt(parts[1])
                root.tooltip = "/ — Size: " + parts[2] + "  Used: " + parts[3] + "  Avail: " + parts[0] + "  Use: " + parts[1]
                var free = 100 - root.usePct
                root.warnClass = free < 10 ? "critical" : (free < 20 ? "warning" : "")
            }
        }
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: storProc.running = true }

    StatChip {
        id: chip
        anchors.fill: parent
        icon: "\u{f0a0}"
        value: root.avail
        iconColor: root.warnClass === "critical" ? Theme.error : root.warnClass === "warning" ? Theme.warning : Theme.surfaceTextVariant
        valueColor: root.warnClass === "critical" ? Theme.error : root.warnClass === "warning" ? Theme.warning : Theme.surfaceTextVariant
        tooltipText: root.tooltip
    }
}
