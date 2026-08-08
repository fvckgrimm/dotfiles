import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    implicitHeight: 26
    implicitWidth: Math.max(clockText.implicitWidth, timerTextItem.implicitWidth) + Theme.spacingLg * 2
    signal clockClicked()
    signal clockRightClicked()
    property string timeStr: ""
    property string timerText: ""   // countdown shown when a timer is set; "" = none
    property bool showTimer: false  // toggled by scroll wheel
    property bool hovered: ma.containsMouse

    // Auto-revert to the clock when the timer runs out / is reset.
    onTimerTextChanged: if (timerText === "") showTimer = false

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
        color: root.timerTintActive ? root.timerTint : Theme.surfaceText
        font.family: Theme.fontFamily
        font.pointSize: Theme.bodyMedium
        font.bold: true
        visible: !root.showTimer
    }

    Text {
        id: timerTextItem
        anchors.centerIn: parent
        text: "󰔠 " + root.timerText
        color: root.timerTintActive ? root.timerTint : Theme.success
        font.family: Theme.fontFamily
        font.pointSize: Theme.bodyMedium
        font.bold: true
        visible: root.showTimer
    }

    // ── Running-timer tint ────────────────────────────────────────────────
    // Set "false" (or delete this block) to revert to the plain clock color.
    readonly property bool timerTintActive: timerText !== ""
    readonly property color timerTint: Theme.primary

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.clockRightClicked()
            else root.clockClicked()
        }
        onWheel: wheel => {
            if (root.timerText !== "" && wheel.angleDelta.y !== 0) root.showTimer = !root.showTimer
        }
    }
}
