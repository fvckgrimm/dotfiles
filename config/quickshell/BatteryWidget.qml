import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    implicitHeight: 22
    implicitWidth: chip.implicitWidth

    property int capacity: 100
    property string status: "Unknown"   // Charging / Discharging / Full / Not charging

    readonly property bool isCharging: status === "Charging"
    readonly property bool isFull:     status === "Full"
    readonly property bool isCritical: capacity <= 15 && !isCharging
    readonly property bool isWarning:  capacity <= 30 && !isCharging

    readonly property string batIcon: {
        if (isCharging) return "\u{f0084}"
        if (isFull)     return "\u{f0079}"
        if (capacity > 80) return "\u{f0082}"
        if (capacity > 60) return "\u{f0080}"
        if (capacity > 40) return "\u{f007e}"
        if (capacity > 20) return "\u{f007c}"
        return "\u{f007a}"
    }

    readonly property string batColor: {
        if (isCharging || isFull) return "#00ff9d"
        if (isCritical)           return "#ff0000"
        if (isWarning)            return "#ffaa00"
        return "#00ff9d"
    }

    Process {
        id: capProc
        command: ["bash", "-c",
            "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var v = parseInt(data.trim())
                if (!isNaN(v)) root.capacity = v
            }
        }
    }

    Process {
        id: statusProc
        command: ["bash", "-c",
            "cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => root.status = data.trim()
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: { capProc.running = true; statusProc.running = true }
    }

    StatChip {
        id: chip
        anchors.fill: parent
        icon: root.batIcon
        value: root.capacity + "%"
        iconColor: root.batColor
        valueColor: root.batColor
        accentColor: "transparent"
        tooltipText: "Battery: " + root.capacity + "%  [" + root.status + "]"

        // Critical blink
        SequentialAnimation on opacity {
            running: root.isCritical
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 500 }
            NumberAnimation { to: 1.0; duration: 500 }
        }
    }
}
