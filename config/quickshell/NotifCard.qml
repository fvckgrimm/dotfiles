import QtQuick
import QtQuick.Layouts

// Individual notification toast card — with action buttons + snooze
Item {
    id: card

    property var notif: null
    property int cardWidth: 360
    property int cardHeight: 90
    property bool expanded: false

    signal dismissed()

    // Expand height if there are actions or if text is expanded
    readonly property bool hasActions: (notif?.actions?.length ?? 0) > 0
    readonly property int  baseHeight: cardHeight
    readonly property int  fullHeight: {
        var h = cardHeight
        if (hasActions) h += 28
        if (expanded) h += Math.max(0, bodyText.implicitHeight - 32)
        return h
    }

    implicitWidth:  cardWidth
    implicitHeight: fullHeight
    
    Behavior on implicitHeight {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    // Slide in from right
    x: cardWidth + 20
    Component.onCompleted: slideIn.start()

    NumberAnimation {
        id: slideIn
        target: card; property: "x"
        to: 0; duration: 260; easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: slideOut
        NumberAnimation {
            target: card; property: "x"
            to: cardWidth + 20; duration: 200; easing.type: Easing.InCubic
        }
        ScriptAction { script: card.dismissed() }
    }

    function dismiss() { slideOut.start() }

    readonly property int    urgency:      notif?.urgency ?? 1
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

    // Snooze menu state
    property bool snoozeOpen: false

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: 6
        color: "#f00d1117"
        border.color: card.borderColor
        border.width: 1
        clip: true

        // Urgency stripe
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 1 }
            width: 3; radius: 3
            color: card.urgencyColor
        }

        // Progress bar
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 4 }
            height: 2; radius: 1
            color: "#0d0df0ff"
            visible: !card.hasActions && !card.expanded // hide when actions row is there or expanded

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
            anchors { fill: parent; margins: 10; leftMargin: 16; bottomMargin: (card.hasActions || card.expanded) ? 4 : 12 }
            spacing: 3

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: card.notif?.appName ?? ""
                    color: "#7984a4"
                    font.family: Theme.fontFamily; font.pointSize: 7; font.bold: true
                    Layout.fillWidth: true; elide: Text.ElideRight
                }

                Text {
                    text: card.notif?.time ?? ""
                    color: "#444d62"
                    font.family: Theme.fontFamily; font.pointSize: 7
                }

                // Copy button
                Text {
                    text: "󰆏"
                    color: copyMa.containsMouse ? Theme.cyan : "#555e7a"
                    font.pointSize: 8
                    Behavior on color { ColorAnimation { duration: 100 } }
                    MouseArea {
                        id: copyMa
                        anchors { fill: parent; margins: -4 }
                        hoverEnabled: true
                        onClicked: {
                            var textToCopy = (card.notif?.summary ? card.notif.summary + "\n" : "") + (card.notif?.body ?? "")
                            // Use bash and printf to safely pipe text to wl-copy
                            Quickshell.execDetached(["bash", "-c", "printf '%s' " + JSON.stringify(textToCopy) + " | wl-copy"])
                        }
                    }
                }

                // Snooze button
                Text {
                    text: "󰒲"
                    color: snoozeBtn.containsMouse ? "#0df0ff" : "#555e7a"
                    font.pointSize: 8
                    Behavior on color { ColorAnimation { duration: 100 } }
                    MouseArea {
                        id: snoozeBtn
                        anchors { fill: parent; margins: -4 }
                        hoverEnabled: true
                        onClicked: card.snoozeOpen = !card.snoozeOpen
                    }
                }

                Text {
                    text: "✕"; color: "#ff416c"; font.pointSize: 8
                    MouseArea { anchors.fill: parent; onClicked: card.dismiss() }
                }
            }

            // Summary
            Text {
                text: card.notif?.summary ?? ""
                color: "#d8e0f0"
                font.family: Theme.fontFamily; font.pointSize: 9; font.bold: true
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                maximumLineCount: 1; elide: Text.ElideRight
                visible: text !== ""
            }

            // Body
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                visible: (card.notif?.body ?? "") !== ""

                Text {
                    id: bodyText
                    text: card.notif?.body ?? ""
                    color: "#9aa5c4"
                    font.family: Theme.fontFamily; font.pointSize: 8
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                    maximumLineCount: card.expanded ? 20 : 2
                    elide: Text.ElideRight
                }

                Text {
                    id: expandToggle
                    text: card.expanded ? "Show less" : "Show more"
                    color: Theme.cyan
                    font.family: Theme.fontFamily; font.pointSize: 7
                    visible: bodyText.lineCount > 2 || card.expanded
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: card.expanded = !card.expanded
                    }
                }
            }

            // Action buttons row
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: card.hasActions && !card.snoozeOpen

                Repeater {
                    model: card.notif?.actions ?? []
                    delegate: Rectangle {
                        required property var modelData
                        implicitWidth:  actionLbl.implicitWidth + 14
                        implicitHeight: 20
                        radius: 3
                        color: actionMa.containsMouse ? "#220df0ff" : "#110d1117"
                        border.color: "#330df0ff"; border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            id: actionLbl
                            anchors.centerIn: parent
                            text: modelData.label
                            color: "#0df0ff"
                            font.family: Theme.fontFamily; font.pointSize: 7
                            elide: Text.ElideRight
                        }
                        MouseArea {
                            id: actionMa
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                NotificationService.invokeAction(card.notif, modelData.id)
                                card.dismiss()
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // Snooze picker row (replaces actions when open)
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: card.snoozeOpen

                Text {
                    text: "snooze:"
                    color: "#555e7a"; font.family: Theme.fontFamily; font.pointSize: 7
                }

                Repeater {
                    model: [
                        { label: "5m",  mins: 5  },
                        { label: "15m", mins: 15 },
                        { label: "30m", mins: 30 },
                        { label: "1h",  mins: 60 },
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        implicitWidth:  snoozeLbl.implicitWidth + 12
                        implicitHeight: 20
                        radius: 3
                        color: snoozeMa.containsMouse ? "#220df0ff" : "transparent"
                        border.color: "#330df0ff"; border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            id: snoozeLbl
                            anchors.centerIn: parent
                            text: modelData.label
                            color: "#7984a4"; font.family: Theme.fontFamily; font.pointSize: 7
                        }
                        MouseArea {
                            id: snoozeMa
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                NotificationService.snooze(card.notif, modelData.mins)
                                card.dismiss()
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "✕"; color: "#555e7a"; font.pointSize: 7
                    MouseArea { anchors.fill: parent; onClicked: card.snoozeOpen = false }
                }
            }
        }

        // Click backdrop to dismiss (but not when clicking buttons)
        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onClicked: mouse => { if (mouse.accepted) card.dismiss() }
        }
    }
}
