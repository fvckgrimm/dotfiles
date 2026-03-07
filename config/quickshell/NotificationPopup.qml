import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Floating notification popup — appears top-right, auto-dismisses after timeout
// Anchored to the bar PanelWindow, positioned top-right
PopupWindow {
    id: root

    
    required property var barWindow   // the PanelWindow from Bar.qml

    // Queue of notifications waiting to be shown
    property var queue: []
    property var current: null
    property bool showing: false

    implicitWidth: 360
    implicitHeight: notifContent.implicitHeight + 24
    color: "transparent"

    // Anchor to the bar, appear just below it on the right side
    anchor.window: root.barWindow
    anchor.rect.x: root.barWindow.width - implicitWidth - 12
    anchor.rect.y: root.barWindow.implicitHeight + 4
    anchor.rect.width: 1
    anchor.rect.height: 1

    visible: showing

    // Auto-dismiss timer
    Timer {
        id: dismissTimer
        interval: 5000
        onTriggered: root.dismiss()
    }

    // Urgency-based timeout: critical stays longer
    function timeoutForUrgency(urgency) {
        // urgency: 0=low, 1=normal, 2=critical
        if (urgency === 2) return 10000
        if (urgency === 0) return 3000
        return 5000
    }

    function show(notif) {
        root.queue.push(notif)
        if (!root.showing) showNext()
    }

    function showNext() {
        if (root.queue.length === 0) { root.showing = false; return }
        root.current = root.queue.shift()
        root.showing = true
        dismissTimer.interval = timeoutForUrgency(root.current.urgency ?? 1)
        dismissTimer.restart()
        slideIn.restart()
    }

    function dismiss() {
        dismissTimer.stop()
        slideOut.start()
    }

    // Connect to service
    Connections {
        target: NotificationService
        function onNewNotification(notif) { root.show(notif) }
    }

    // ── Slide animations ────────────────────────────────────────────────────
    NumberAnimation {
        id: slideIn
        target: popup
        property: "x"
        from: root.implicitWidth + 20
        to: 0
        duration: 250
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: slideOut
        NumberAnimation {
            target: popup
            property: "x"
            to: root.implicitWidth + 20
            duration: 200
            easing.type: Easing.InCubic
        }
        ScriptAction { script: root.showNext() }
    }

    // ── Popup card ──────────────────────────────────────────────────────────
    Item {
        id: popup
        anchors.fill: parent
        clip: true

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: 6
            color: "#f00d1117"
            border.color: {
                var u = root.current?.urgency ?? 1
                if (u === 2) return "#80ff0000"
                if (u === 0) return "#337984a4"
                return "#335bcefa"
            }
            border.width: 1

            // Left urgency stripe
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 1 }
                width: 3
                radius: 3
                color: {
                    var u = root.current?.urgency ?? 1
                    if (u === 2) return "#ff0000"
                    if (u === 0) return "#7984a4"
                    return "#0df0ff"
                }
            }

            ColumnLayout {
                id: notifContent
                anchors { fill: parent; margins: 12; leftMargin: 18 }
                spacing: 4

                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    Text {
                        text: root.current?.appName ?? ""
                        color: "#7984a4"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pointSize: 7
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.current?.time ?? ""
                        color: "#555e7a"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pointSize: 7
                    }

                    // Close button
                    Text {
                        text: "✕"
                        color: "#ff416c"
                        font.pointSize: 8
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.dismiss()
                        }
                    }
                }

                Text {
                    text: root.current?.summary ?? ""
                    color: "#d8e0f0"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pointSize: 9
                    font.bold: true
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    visible: text !== ""
                }

                Text {
                    text: root.current?.body ?? ""
                    color: "#9aa5c4"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pointSize: 8
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                    visible: text !== ""
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.dismiss()
            }
        }

        // Progress bar showing remaining time
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 5 }
            height: 2
            radius: 1
            color: "#1a0df0ff"

            Rectangle {
                id: progressBar
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                radius: 1
                color: "#550df0ff"
                width: parent.width

                NumberAnimation on width {
                    id: progressAnim
                    running: root.showing
                    from: progressBar.parent.width
                    to: 0
                    duration: dismissTimer.interval
                }
            }
        }
    }
}
