import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    implicitHeight: 22
    implicitWidth: chip.implicitWidth

    property string display: "..."
    property string tooltip: ""
    property bool connected: true

    Process {
        id: netProc
        // Gets essid+signal for wifi, or interface name for ethernet
        command: ["bash", "-c", `
            iface=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'dev \\K\\S+')
            if [ -z "$iface" ]; then
                echo "DISCONNECTED"
                exit 0
            fi
            ip=$(ip addr show "$iface" | grep -oP 'inet \\K[\\d.]+' | head -1)
            if [ -d "/sys/class/net/$iface/wireless" ]; then
                essid=$(iwgetid -r "$iface" 2>/dev/null)
                sig=$(awk 'NR==3{printf "%d", ($3/70)*100}' /proc/net/wireless 2>/dev/null)
                echo "WIFI|$essid|$sig|$ip"
            else
                rx=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null || echo 0)
                tx=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null || echo 0)
                echo "ETH|$iface|$ip"
            fi
        `]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var s = data.trim()
                if (s === "DISCONNECTED" || s === "") {
                    root.connected = false
                    root.display   = " "
                    root.tooltip   = "No network"
                    return
                }
                root.connected = true
                var parts = s.split("|")
                if (parts[0] === "WIFI") {
                    root.display = "  " + parts[1] + " (" + parts[2] + "%)"
                    root.tooltip = "WiFi: " + parts[1] + "\nSignal: " + parts[2] + "%\nIP: " + parts[3]
                } else {
                    root.display = "󰈀  " + parts[1]
                    root.tooltip = "Ethernet: " + parts[1] + "\nIP: " + parts[2]
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: netProc.running = true
    }

    StatChip {
        id: chip
        anchors.fill: parent
        icon: ""
        value: root.display
        iconColor: "transparent"    // icon baked into display string
        valueColor: root.connected ? "#0df0ff" : "#f53c3c"
        accentColor: root.connected ? "#800df0ff" : "#80f53c3c"
        bgColor: "#661e1e28"
        tooltipText: root.tooltip

        // Disconnected pulse
        SequentialAnimation on opacity {
            running: !root.connected
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 1000 }
            NumberAnimation { to: 1.0; duration: 1000 }
        }

        onClicked: {
            Quickshell.exec(["bash", "-c", "ip address show up scope global | grep inet | head -n1 | cut -d/ -f1 | awk '{print $2}' | wl-copy"])
        }
        onRightClicked: {
            Quickshell.exec(["bash", "-c", "ip address show up scope global | grep inet6 | head -n1 | cut -d/ -f1 | awk '{print $2}' | wl-copy"])
        }
    }
}
