import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitHeight: 22
    implicitWidth: chip.implicitWidth

    property real usedGb: 0
    property real totalGb: 0
    property int usedPct: 0
    property var history: []
    readonly property int histLen: 30

    Process {
        id: memProc
        command: ["bash", "-c", "cat /proc/meminfo | grep -E '^(MemTotal|MemAvailable):'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var match = data.match(/^(\w+):\s+(\d+)/)
                if (!match) return
                if (match[1] === "MemTotal")     root.totalGb = parseInt(match[2]) / 1048576
                if (match[1] === "MemAvailable") {
                    var avail = parseInt(match[2]) / 1048576
                    root.usedGb  = root.totalGb - avail
                    root.usedPct = root.totalGb > 0
                        ? Math.round((root.usedGb / root.totalGb) * 100) : 0
                    var h = root.history.slice()
                    h.push(root.usedPct)
                    if (h.length > root.histLen) h.shift()
                    root.history = h
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: memProc.running = true
    }

    StatChip {
        id: chip
        anchors.fill: parent
        icon: "\u{f035b}"
        value: root.usedGb.toFixed(1) + "GB"
        iconColor: "#ffcc00"
        valueColor: "#ffcc00"
        accentColor: "#80ffcc00"
        bgColor: "#661e1e28"
        tooltipText: "RAM: " + root.usedGb.toFixed(2) + " / " + root.totalGb.toFixed(1) + " GB  (" + root.usedPct + "%)"
        onClicked: Quickshell.execDetached(["alacritty", "-e", "btop"])

        Canvas {
            id: sparkline
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                rightMargin: 4
            }
            width: 36
            opacity: 0.5

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var h = root.history
                if (h.length < 2) return
                ctx.beginPath()
                ctx.strokeStyle = "#ffcc00"
                ctx.lineWidth = 1
                for (var i = 0; i < h.length; i++) {
                    var x = (i / (root.histLen - 1)) * width
                    var y = height - (h[i] / 100) * height
                    if (i === 0) ctx.moveTo(x, y)
                    else ctx.lineTo(x, y)
                }
                ctx.stroke()
            }

            Connections {
                target: root
                function onHistoryChanged() { sparkline.requestPaint() }
            }
        }
    }
}
