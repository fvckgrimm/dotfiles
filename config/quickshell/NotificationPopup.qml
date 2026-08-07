import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PopupWindow {
    id: root
    required property var barWindow
    readonly property int maxStack:   4
    readonly property int cardHeight: 90
    readonly property int cardSpacing: Theme.spacingSm
    readonly property int cardWidth:  360

    // ListModel instead of a swapped JS array: Repeater reconciles individual
    // inserts/removes in place, so dismissing one card lets the survivors
    // slide up to fill the gap. Swapping a fresh array used to cause a full
    // model reset, which recreated every delegate and replayed their slide-in
    // entrance (the "pop back in like they just arrived" effect).
    ListModel { id: stackModel }

    implicitWidth:  cardWidth
    implicitHeight: Math.max(1, stackModel.count * (cardHeight + cardSpacing + 28))
    color: "transparent"
    visible: stackModel.count > 0 || hideTimer.running

    Timer { id: hideTimer; interval: 300; running: false }

    anchor.window: root.barWindow
    anchor.rect.x: root.barWindow.width - cardWidth - 12
    anchor.rect.y: root.barWindow.implicitHeight + 4
    anchor.rect.width:  1
    anchor.rect.height: 1

    Connections {
        target: NotificationService
        function onNewNotification(notif) {
            if (NotificationService.dndActive) return
            root.push(notif)
        }
    }
    function push(notif) {
        var n = Object.assign({}, notif, { _uid: Date.now() + Math.random() })
        stackModel.insert(0, n)
        if (stackModel.count > root.maxStack) stackModel.remove(stackModel.count - 1)
    }
    function dismiss(uid) {
        for (var i = 0; i < stackModel.count; i++) {
            if (stackModel.get(i)._uid === uid) { stackModel.remove(i); break }
        }
        if (stackModel.count === 0) hideTimer.restart()
    }

    Repeater {
        model: stackModel
        delegate: NotifCard {
            id: card
            required property var modelData
            required property int index
            notif: modelData
            cardWidth:  root.cardWidth
            cardHeight: root.cardHeight
            y: index * (root.cardHeight + root.cardSpacing)
            scale:   1.0 - (index * 0.02)
            opacity: 1.0 - (index * 0.15)
            Behavior on y       { NumberAnimation { duration: Theme.motionMedium; easing.type: Theme.easingStandard } }
            Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
            Behavior on scale   { NumberAnimation { duration: Theme.motionMedium; easing.type: Theme.easingStandard } }
            onDismissed: root.dismiss(modelData._uid)
            Timer {
                // Runs the card's exit animation before removing it from the
                // model, so timeout dismissals fade/slide out too.
                interval: modelData.urgency === 2 ? 10000 : (modelData.urgency === 0 ? 3000 : 5000)
                running: true
                onTriggered: card.dismiss()
            }
        }
    }
}
