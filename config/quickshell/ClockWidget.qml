import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    implicitHeight: 22
    implicitWidth: clockText.implicitWidth + 20

    signal clockClicked()

    property string timeStr: ""

    Process {
        id: clockProc
        command: ["date", "+%I:%M %p  %A %b %d"]
        running: true
        stdout: SplitParser {
            onRead: data => root.timeStr = data.trim()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockProc.running = true
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        text: root.timeStr
        color: "#d8e0f0"
        font.family: "JetBrainsMono Nerd Font"
        font.pointSize: 8
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clockClicked()
    }
}
