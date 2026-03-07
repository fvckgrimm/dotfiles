import QtQuick

// Reusable horizontal slider: 0-100 range
Item {
    id: root
    implicitHeight: 18

    property int value: 0        // 0-100
    property string accentColor: "#0df0ff"

    signal moved(int v)

    Rectangle {
        id: track
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: 4
        radius: 2
        color: "#1a5bcefa"

        Rectangle {
            width: (root.value / 100) * track.width
            height: parent.height
            radius: 2
            color: root.accentColor
            opacity: 0.8
        }
    }

    // Thumb
    Rectangle {
        x: (root.value / 100) * (track.width - width)
        anchors.verticalCenter: track.verticalCenter
        width: 12; height: 12; radius: 6
        color: root.accentColor
        border.color: "#d90d1117"
        border.width: 2
    }

    MouseArea {
        anchors.fill: parent
        onClicked: mouse => emitValue(mouse.x)
        onPositionChanged: mouse => { if (pressed) emitValue(mouse.x) }
    }

    function emitValue(mouseX) {
        var v = Math.max(0, Math.min(100, Math.round((mouseX / width) * 100)))
        root.value = v
        root.moved(v)
    }
}
