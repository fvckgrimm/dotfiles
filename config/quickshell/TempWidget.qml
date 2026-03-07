import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    implicitHeight: 22
    implicitWidth: chip.implicitWidth

    property int tempC: 0
    readonly property bool isCritical: tempC >= 80

    readonly property string tempIcon: tempC < 50 ? "\u{f0f54}" : (tempC < 70 ? "\u{f0f55}" : "\u{f0f58}")

    Process {
        id: tempProc
        command: ["bash", "-c",
            "sensors 2>/dev/null | grep -oP 'temp1:\\s+\\+\\K[0-9]+' | head -1 || " +
            "cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{printf \"%d\", $1/1000}'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var v = parseInt(data.trim())
                if (!isNaN(v)) root.tempC = v
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: tempProc.running = true
    }

    StatChip {
        id: chip
        anchors.fill: parent
        icon: root.tempIcon
        value: root.tempC + "°"
        iconColor: root.isCritical ? "#ff0000" : "#c8d2e0"
        valueColor: root.isCritical ? "#ff0000" : "#c8d2e0"
        accentColor: root.isCritical ? "#80ff0000" : "#50c8d2e0"
        bgColor: "#661e1e28"
        tooltipText: "CPU Temp: " + root.tempC + "°C"
        onClicked: Quickshell.execDetached(["xsensors"])

        // Pulsing animation when critical
        SequentialAnimation on opacity {
            running: root.isCritical
            loops: Animation.Infinite
            NumberAnimation { to: 0.4; duration: 500 }
            NumberAnimation { to: 1.0; duration: 500 }
        }
    }
}
