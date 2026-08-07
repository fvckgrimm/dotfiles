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
    Behavior on implicitHeight { NumberAnimation { duration: Theme.motionMedium; easing.type: Theme.easingStandard } }

    x: cardWidth + 20
    Component.onCompleted: slideIn.start()
    ParallelAnimation {
        id: slideIn
        NumberAnimation { target: card; property: "x"; to: 0; duration: Theme.motionSlow; easing.type: Theme.easingStandard }
        NumberAnimation { target: bg; property: "opacity"; to: 1; duration: Theme.motionSlow; easing.type: Theme.easingStandard }
    }
    SequentialAnimation {
        id: slideOut
        ParallelAnimation {
            NumberAnimation { target: card; property: "x"; to: cardWidth + 20; duration: Theme.motionMedium; easing.type: Easing.InCubic }
            NumberAnimation { target: bg; property: "opacity"; to: 0; duration: Theme.motionMedium; easing.type: Easing.InCubic }
        }
        ScriptAction { script: card.dismissed() }
    }
    function dismiss() { slideOut.start() }

    readonly property int    urgency: notif?.urgency ?? 1
    readonly property string urgencyColor: {
        if (urgency === 2) return Theme.error
        if (urgency === 0) return Theme.surfaceTextDim
        return Theme.primary
    }

    property bool snoozeOpen: false

    Rectangle {
        id: bg
        anchors.fill: parent
        anchors.margins: 3
        radius: Theme.radiusLg
        color: Theme.cardColor()
        clip: true
        opacity: 0.6

        // Urgency dot instead of a full-height stripe + colored border
        Rectangle {
            anchors { left: parent.left; top: parent.top; margins: Theme.spacingMd }
            width: 6; height: 6; radius: 3
            color: card.urgencyColor
        }

        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 4 }
            height: 2; radius: 1
            color: Theme.surfaceContainerHigh
            visible: !card.hasActions && !card.expanded

            Rectangle {
                id: progressFill
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                radius: 1
                color: card.urgencyColor
                opacity: 0.6
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
            anchors { fill: parent; margins: Theme.spacingMd; leftMargin: Theme.spacingXl; bottomMargin: (card.hasActions || card.expanded) ? 4 : Theme.spacingMd }
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSm

                Text {
                    text: card.notif?.appName ?? ""
                    color: Theme.surfaceTextVariant
                    font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; font.bold: true
                    Layout.fillWidth: true; elide: Text.ElideRight
                }
                Text {
                    text: card.notif?.time ?? ""
                    color: Theme.surfaceTextDim
                    font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                }
                Text {
                    text: "󰆏"
                    color: copyMa.containsMouse ? Theme.primary : Theme.surfaceTextDim
                    font.pointSize: Theme.labelLarge
                    MouseArea {
                        id: copyMa
                        anchors { fill: parent; margins: -4 }
                        hoverEnabled: true
                        onClicked: {
                            var textToCopy = (card.notif?.summary ? card.notif.summary + "\n" : "") + (card.notif?.body ?? "")
                            Quickshell.execDetached(["bash", "-c", "printf '%s' " + JSON.stringify(textToCopy) + " | wl-copy"])
                        }
                    }
                }
                Text {
                    text: "󰒲"
                    color: snoozeBtn.containsMouse ? Theme.primary : Theme.surfaceTextDim
                    font.pointSize: Theme.labelLarge
                    MouseArea {
                        id: snoozeBtn
                        anchors { fill: parent; margins: -4 }
                        hoverEnabled: true
                        onClicked: card.snoozeOpen = !card.snoozeOpen
                    }
                }
                Text {
                    text: "✕"; color: Theme.error; font.pointSize: Theme.labelLarge
                    MouseArea { anchors.fill: parent; onClicked: card.dismiss() }
                }
            }

            Text {
                text: card.notif?.summary ?? ""
                color: Theme.surfaceText
                font.family: Theme.fontFamily; font.pointSize: Theme.bodyLarge; font.bold: true
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                maximumLineCount: 1; elide: Text.ElideRight
                visible: text !== ""
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingXs
                visible: (card.notif?.body ?? "") !== ""

                Text {
                    id: bodyText
                    text: card.notif?.body ?? ""
                    color: Theme.surfaceTextVariant
                    font.family: Theme.fontFamily; font.pointSize: Theme.bodyMedium
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                    maximumLineCount: card.expanded ? 20 : 2
                    elide: Text.ElideRight
                }
                Text {
                    text: card.expanded ? "Show less" : "Show more"
                    color: Theme.primary
                    font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                    visible: bodyText.lineCount > 2 || card.expanded
                    MouseArea { anchors.fill: parent; onClicked: card.expanded = !card.expanded }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingXs
                visible: card.hasActions && !card.snoozeOpen

                Repeater {
                    model: card.notif?.actions ?? []
                    delegate: Rectangle {
                        required property var modelData
                        implicitWidth:  actionLbl.implicitWidth + Theme.spacingMd
                        implicitHeight: 22
                        radius: Theme.radiusSm
                        color: actionMa.containsMouse ? Theme.withAlpha(Theme.primary, 0.2) : Theme.withAlpha(Theme.primary, 0.1)

                        Text {
                            id: actionLbl
                            anchors.centerIn: parent
                            text: modelData.label
                            color: Theme.primary
                            font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                            elide: Text.ElideRight
                        }
                        MouseArea {
                            id: actionMa
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: { NotificationService.invokeAction(card.notif, modelData.id); card.dismiss() }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingXs
                visible: card.snoozeOpen

                Text { text: "snooze:"; color: Theme.surfaceTextDim; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge }

                Repeater {
                    model: [
                        { label: "5m",  mins: 5  },
                        { label: "15m", mins: 15 },
                        { label: "30m", mins: 30 },
                        { label: "1h",  mins: 60 },
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        implicitWidth:  snoozeLbl.implicitWidth + Theme.spacingMd
                        implicitHeight: 22
                        radius: Theme.radiusSm
                        color: snoozeMa.containsMouse ? Theme.withAlpha(Theme.primary, 0.2) : "transparent"

                        Text {
                            id: snoozeLbl
                            anchors.centerIn: parent
                            text: modelData.label
                            color: Theme.surfaceTextVariant; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                        }
                        MouseArea {
                            id: snoozeMa
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: { NotificationService.snooze(card.notif, modelData.mins); card.dismiss() }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "✕"; color: Theme.surfaceTextDim; font.pointSize: Theme.labelLarge
                    MouseArea { anchors.fill: parent; onClicked: card.snoozeOpen = false }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onClicked: mouse => { if (mouse.accepted) card.dismiss() }
        }
    }
}
