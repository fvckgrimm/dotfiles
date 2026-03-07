import QtQuick
import QtQuick.Layouts

// Individual notification toast card
Item {
    id: card

    property var notif: null
    property int cardWidth: 360
    property int cardHeight: 90

    signal dismissed()

    implicitWidth: cardWidth
    implicitHeight: cardHeight

    // Slide in from right on creation
    x: cardWidth + 20
    Component.onCompleted: slideIn.start()

    NumberAnimation {
        id: slideIn
        target: card
        property: "x"
        to: 0
        duration: 260
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: slideOut
        NumberAnimation {
            target: card
            property: "x"
            to: cardWidth + 20
            duration: 200
            easing.type: Easing.InCubic
        }
        ScriptAction { script: card.dismissed() }
    }

    function dismiss() { slideOut.start() }

    readonly property int urgency: notif?.urgency ?? 1
    readonly property string urgencyColor: {
        if (urgency === 2) return "#ff0000"
        if (urgency === 0) return "#555e7a"
        return "#0df0ff"
    }
    readonly property string borderColor: {
        if (urgency === 2) return "#80ff0000"
        if (urgency === 0) return "#337984a4"
        return "#335bcefa"
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: 6
        color: "#f00d1117"
        border.color: card.borderColor
        border.width: 1

        // Urgency stripe on left
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 1 }
            width: 3
            radius: 3
            color: card.urgencyColor
        }

        // Progress bar — drains from full to empty over the auto-dismiss duration
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 4 }
            height: 2
            radius: 1
            color: "#0d0df0ff"

            Rectangle {
                id: progressFill
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                radius: 1
                color: card.urgencyColor
                opacity: 0.5
                width: parent.width

                NumberAnimation on width {
                    running: true
                    from: progressFill.parent.width
                    to: 0
                    duration: card.urgency === 2 ? 10000 : (card.urgency === 0 ? 3000 : 5000)
                }
            }
        }

        ColumnLayout {
            anchors { fill: parent; margins: 10; leftMargin: 16; bottomMargin: 12 }
            spacing: 3

            // Header: app name + time + close
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: card.notif?.appName ?? ""
                    color: "#7984a4"
                    font.family: Theme.fontFamily
                    font.pointSize: 7
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: card.notif?.time ?? ""
                    color: "#444d62"
                    font.family: Theme.fontFamily
                    font.pointSize: 7
                }

                Text {
                    text: "✕"
                    color: "#ff416c"
                    font.pointSize: 8
                    MouseArea {
                        anchors.fill: parent
                        onClicked: card.dismiss()
                    }
                }
            }

            // Summary
            Text {
                text: card.notif?.summary ?? ""
                color: "#d8e0f0"
                font.family: Theme.fontFamily
                font.pointSize: 9
                font.bold: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                maximumLineCount: 1
                elide: Text.ElideRight
                visible: text !== ""
            }

            // Body
            Text {
                text: card.notif?.body ?? ""
                color: "#9aa5c4"
                font.family: Theme.fontFamily
                font.pointSize: 8
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                textFormat: Text.PlainText
                maximumLineCount: 2
                elide: Text.ElideRight
                visible: text !== ""
            }
        }

        // Click anywhere on card to dismiss
        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onClicked: mouse => {
                // Only dismiss if not clicking the X button
                if (mouse.accepted) card.dismiss()
            }
        }
    }
}
