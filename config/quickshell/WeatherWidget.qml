import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    implicitHeight: 26
    implicitWidth: chip.implicitWidth
    property string display: "..."
    property string tooltip: ""

    Process {
        id: weatherProc
        command: ["bash", "-c", "curl -sf 'https://wttr.in/?format=1' 2>/dev/null || echo '? N/A'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var s = data.trim()
                root.display = s !== "" ? s : "? N/A"
                root.tooltip = "Weather (wttr.in)\n" + s
            }
        }
    }
    Timer { interval: 3600000; running: true; repeat: true; onTriggered: weatherProc.running = true }

    StatChip {
        id: chip
        anchors.fill: parent
        icon: ""
        value: root.display
        iconColor: "transparent"
        valueColor: Theme.surfaceTextVariant
        tooltipText: root.tooltip
    }
}
