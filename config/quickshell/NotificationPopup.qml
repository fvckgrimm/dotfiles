import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PopupWindow {
    id: root

    required property var barWindow

    property var stack: []
    readonly property int maxStack: 4
    readonly property int cardHeight: 90
    readonly property int cardSpacing: 8
    readonly property int cardWidth: 360

    // NEVER let height go to 0 — that sends an invalid size to the compositor
    // and crashes the Wayland connection. Always keep at least 1px.
    implicitWidth: cardWidth
    implicitHeight: Math.max(1, stack.length * (cardHeight + cardSpacing))
    color: "transparent"

    // Only show when there are cards — but delay hiding until after slide-out
    // animations finish so the window isn't destroyed mid-animation
    visible: stack.length > 0 || hideTimer.running

    Timer {
        id: hideTimer
        interval: 300   // matches slideOut duration in NotifCard
        running: false
    }

    anchor.window: root.barWindow
    anchor.rect.x: root.barWindow.width - cardWidth - 12
    anchor.rect.y: root.barWindow.implicitHeight + 4
    anchor.rect.width: 1
    anchor.rect.height: 1

    Connections {
        target: NotificationService
        function onNewNotification(notif) { root.push(notif) }
    }

    function push(notif) {
        var n = Object.assign({}, notif, { _uid: Date.now() + Math.random() })
        var s = root.stack.slice()
        s.unshift(n)
        if (s.length > maxStack) s = s.slice(0, maxStack)
        root.stack = s
    }

    function dismiss(uid) {
        root.stack = root.stack.filter(n => n._uid !== uid)
        // If stack is now empty, let the hide timer run so the window
        // stays alive long enough for the slide-out animation to finish
        if (root.stack.length === 0) hideTimer.restart()
    }

    Repeater {
        model: root.stack

        delegate: NotifCard {
            required property var modelData
            required property int index

            notif: modelData
            cardWidth: root.cardWidth
            cardHeight: root.cardHeight
            y: index * (root.cardHeight + root.cardSpacing)
            scale: 1.0 - (index * 0.02)
            opacity: 1.0 - (index * 0.15)

            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 150 } }

            onDismissed: root.dismiss(modelData._uid)

            Timer {
                interval: modelData.urgency === 2 ? 10000 : (modelData.urgency === 0 ? 3000 : 5000)
                running: true
                onTriggered: root.dismiss(modelData._uid)
            }
        }
    }
}
