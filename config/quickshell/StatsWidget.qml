import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// StatsWidget — compact CPU/MEM summary chip in the bar. Clicking opens the
// Dashboard on the "stats" tab (full at-a-glance overview). Toggle via
// SettingsService.showStats.
Item {
    id: root
    implicitHeight: 26
    implicitWidth: chip.implicitWidth

    signal clicked()

    property int cpu: 0
    property int mem: 0

    Process {
        id: cpuProc
        command: ["bash", "-c", "top -bn2 -d 0.1 | grep 'Cpu(s)' | tail -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var m = data.match(/(\d+(?:\.\d+)?)\s+id/)
                if (m) root.cpu = Math.max(0, Math.min(100, Math.round(100 - parseFloat(m[1]))))
            }
        }
    }
    Process {
        id: memProc
        command: ["bash", "-c", "cat /proc/meminfo | grep -E '^(MemTotal|MemAvailable):'"]
        running: true
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var m = data.match(/MemTotal:\s+(\d+)/)
                var total = m ? parseInt(m[1]) : 0
                m = data.match(/MemAvailable:\s+(\d+)/)
                var avail = m ? parseInt(m[1]) : 0
                if (total > 0) root.mem = Math.round((total - avail) / total * 100)
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: { cpuProc.running = true; memProc.running = true } }

    StatChip {
        id: chip
        anchors.fill: parent
        icon: "󰻠"
        value: root.cpu + "% " + root.mem + "%"
        iconColor: Theme.primary
        valueColor: Theme.surfaceText
        tooltipText: "System Stats — CPU " + root.cpu + "% · MEM " + root.mem + "%"
        onClicked: root.clicked()
    }
}
