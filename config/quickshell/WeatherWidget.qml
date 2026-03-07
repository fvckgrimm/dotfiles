import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    implicitHeight: 22
    implicitWidth: chip.implicitWidth

    property string display: "..."
    property string tooltip: ""

    Process {
        id: weatherProc
        // Reuses your existing wttr.in one-liner from config.jsonc
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

    // Refresh every hour, same as your old waybar interval
    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: weatherProc.running = true
    }

    StatChip {
        id: chip
        anchors.fill: parent
        icon: ""
        value: root.display
        iconColor: "transparent"    // emoji baked in from wttr
        valueColor: "#c8d2e0"
        accentColor: "#50c8d2e0"
        bgColor: "#661e1e28"
        tooltipText: root.tooltip
    }
}
