import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    implicitHeight: 26
    implicitWidth: clockText.implicitWidth + Theme.spacingLg * 2
    signal clockClicked()
    property string timeStr: ""
    property bool hovered: ma.containsMouse

    Process {
        id: clockProc
        command: ["date", "+%I:%M %p  %A %b %d"]
        running: true
        stdout: SplitParser { onRead: data => root.timeStr = data.trim() }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: clockProc.running = true }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMd
        color: root.hovered ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        text: root.timeStr
        color: Theme.surfaceText
        font.family: Theme.fontFamily
        font.pointSize: Theme.bodyMedium
        font.bold: true
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clockClicked()
    }
}
