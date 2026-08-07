import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// CPU usage — polls /proc/stat directly, shows mini sparkline
Item {
    id: root
    implicitHeight: 26
    implicitWidth: chip.implicitWidth
    property int usage: 0
    property var history: []
    readonly property int histLen: 30
    property var _prev: null

    Process {
        id: cpuProc
        command: ["bash", "-c", "cat /proc/stat | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(/\s+/)
                var user = parseInt(parts[1]), nice = parseInt(parts[2]), system = parseInt(parts[3])
                var idle = parseInt(parts[4]), iowait = parseInt(parts[5]), irq = parseInt(parts[6]), softirq = parseInt(parts[7])
                var total = user + nice + system + idle + iowait + irq + softirq
                var active = total - idle - iowait
                if (root._prev) {
                    var dTotal = total - root._prev.total
                    var dActive = active - root._prev.active
                    root.usage = dTotal > 0 ? Math.round((dActive / dTotal) * 100) : 0
                }
                root._prev = { total: total, active: active }
                var h = root.history.slice()
                h.push(root.usage)
                if (h.length > root.histLen) h.shift()
                root.history = h
            }
        }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: cpuProc.running = true }

    StatChip {
        id: chip
        anchors.fill: parent
        icon: "\u{f4bc}"
        value: root.usage + "%"
        iconColor: Theme.error
        valueColor: Theme.error
        tooltipText: "CPU Usage: " + root.usage + "%"
        onClicked: Quickshell.execDetached(["alacritty", "-e", "btop"])

        Canvas {
            id: sparkline
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom; rightMargin: 4 }
            width: 32
            opacity: 0.5
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var h = root.history
                if (h.length < 2) return
                ctx.beginPath()
                ctx.strokeStyle = Theme.error
                ctx.lineWidth = 1
                for (var i = 0; i < h.length; i++) {
                    var x = (i / (root.histLen - 1)) * width
                    var y = height - (h[i] / 100) * height
                    if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                }
                ctx.stroke()
            }
            Connections { target: root; function onHistoryChanged() { sparkline.requestPaint() } }
        }
    }
}
