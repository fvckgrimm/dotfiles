import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Notification center — three-tab panel: Notifications | Do Not Disturb | App Filters
PopupWindow {
    id: root

    implicitWidth:  400
    implicitHeight: Math.min(mainCol.implicitHeight + Theme.spacingXl * 2, 640)
    color: "transparent"

    property string tab: "notifs"

    onVisibleChanged: {
        if (visible) {
            NotificationService.markAllRead()
            tab = "notifs"
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.spacingXs
        radius: Theme.radiusXl
        color: Theme.cardColor()
        border.color: Theme.cardBorder()
        border.width: 1
        clip: true

        ColumnLayout {
            id: mainCol
            anchors { fill: parent; margins: Theme.spacingLg }
            spacing: Theme.spacingMd

            // ── Tab bar ───────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingXs

                Repeater {
                    model: [
                        { id: "notifs",  label: "󰂚  Notifications" },
                        { id: "dnd",     label: "󰂛  Do Not Disturb" },
                        { id: "filters", label: "󰈈  App Filters" },
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool active: root.tab === modelData.id
                        Layout.fillWidth: true
                        height: 28
                        color: active ? Theme.withAlpha(Theme.primary, 0.16) : "transparent"
                        radius: Theme.radiusMd
                        Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: active ? Theme.primary : Theme.surfaceTextVariant
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.labelLarge
                            font.bold: active
                            Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.tab = modelData.id }
                    }
                }

                Rectangle {
                    implicitWidth: dndPillLbl.implicitWidth + Theme.spacingLg
                    implicitHeight: 24
                    radius: Theme.radiusFull
                    color: NotificationService.dndActive ? Theme.withAlpha(Theme.error, 0.18) : Theme.surfaceContainerHigh
                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                    Text {
                        id: dndPillLbl
                        anchors.centerIn: parent
                        text: NotificationService.dndActive ? "DnD ON" : "DnD OFF"
                        color: NotificationService.dndActive ? Theme.error : Theme.surfaceTextDim
                        font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall; font.bold: true
                    }
                    MouseArea { anchors.fill: parent; onClicked: NotificationService.dndEnabled = !NotificationService.dndEnabled }
                }

                Rectangle {
                    implicitWidth: 20; implicitHeight: 20; radius: Theme.radiusSm
                    color: closeMa.containsMouse ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : "transparent"
                    Text { anchors.centerIn: parent; text: "✕"; color: Theme.surfaceTextVariant; font.pointSize: Theme.labelLarge }
                    MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.visible = false }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outlineVariant }

            // ══════════════════ TAB: NOTIFICATIONS ══════════════════
            Item {
                Layout.fillWidth: true
                implicitHeight: notifsCol.implicitHeight
                visible: root.tab === "notifs"

                ColumnLayout {
                    id: notifsCol
                    width: parent.width
                    spacing: Theme.spacingSm

                    RowLayout {
                        Layout.fillWidth: true

                        Rectangle {
                            visible: NotificationService.snoozed.length > 0
                            implicitWidth: snoozeBadge.implicitWidth + Theme.spacingLg
                            implicitHeight: 22; radius: Theme.radiusSm
                            color: Theme.surfaceContainerHigh
                            Text {
                                id: snoozeBadge
                                anchors.centerIn: parent
                                text: "󰒲 " + NotificationService.snoozed.length + " snoozed"
                                color: Theme.surfaceTextVariant; font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            visible: (NotificationService.notifications?.length ?? 0) > 0
                            implicitWidth: clearAllLbl.implicitWidth + Theme.spacingLg; implicitHeight: 22
                            radius: Theme.radiusSm
                            color: clearAllMa.containsMouse ? Theme.withAlpha(Theme.error, 0.16) : "transparent"
                            Text {
                                id: clearAllLbl; anchors.centerIn: parent
                                text: "Clear all"; color: Theme.error
                                font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                            }
                            MouseArea { id: clearAllMa; anchors.fill: parent; hoverEnabled: true; onClicked: NotificationService.clearAll() }
                        }
                    }

                    Item {
                        Layout.fillWidth: true; implicitHeight: 60
                        visible: (NotificationService.notifications?.length ?? 0) === 0
                        Text {
                            anchors.centerIn: parent
                            text: NotificationService.dndActive ? "󰂛  Do not disturb is on" : "No notifications"
                            color: Theme.surfaceTextDim; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                        }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        implicitHeight: Math.min(notifListCol.implicitHeight, 460)
                        contentHeight:  notifListCol.implicitHeight
                        clip: true
                        visible: (NotificationService.notifications?.length ?? 0) > 0

                        ColumnLayout {
                            id: notifListCol
                            width: parent.width
                            spacing: Theme.spacingMd

                            Repeater {
                                model: NotificationService.groupedNotifications

                                delegate: ColumnLayout {
                                    id: groupCol
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: Theme.spacingSm
                                    property bool expanded: false

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: topItemLayout.implicitHeight + Theme.spacingLg
                                        radius: Theme.radiusLg
                                        color: groupMa.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer

                                        MouseArea {
                                            id: groupMa; anchors.fill: parent; hoverEnabled: true
                                            onClicked: { if (modelData.notifications.length > 1) groupCol.expanded = !groupCol.expanded }
                                        }

                                        // Urgency dot instead of a full-height stripe
                                        Rectangle {
                                            anchors { left: parent.left; top: parent.top; margins: Theme.spacingMd }
                                            width: 6; height: 6; radius: 3
                                            color: {
                                                var u = modelData.notifications[0].urgency ?? 1
                                                if (u === 2) return Theme.error
                                                if (u === 0) return Theme.surfaceTextDim
                                                return Theme.primary
                                            }
                                        }

                                        ColumnLayout {
                                            id: topItemLayout
                                            anchors { fill: parent; margins: Theme.spacingMd; leftMargin: Theme.spacingXl }
                                            spacing: Theme.spacingXs

                                            RowLayout {
                                                Layout.fillWidth: true; spacing: Theme.spacingSm

                                                Text {
                                                    text: modelData.appName; color: Theme.surfaceTextVariant
                                                    font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; font.bold: true
                                                    Layout.fillWidth: true; elide: Text.ElideRight
                                                }

                                                Rectangle {
                                                    visible: modelData.notifications.length > 1
                                                    implicitWidth: stackCount.implicitWidth + Theme.spacingMd
                                                    implicitHeight: 18; radius: Theme.radiusFull
                                                    color: Theme.withAlpha(Theme.primary, 0.16)
                                                    Text {
                                                        id: stackCount
                                                        anchors.centerIn: parent
                                                        text: modelData.notifications.length
                                                        color: Theme.primary; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; font.bold: true
                                                    }
                                                }

                                                Text {
                                                    text: modelData.notifications[0].time; color: Theme.surfaceTextDim
                                                    font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                                                }

                                                Text {
                                                    text: "󰆏"
                                                    color: copyTopMa.containsMouse ? Theme.primary : Theme.surfaceTextDim
                                                    font.pointSize: Theme.labelLarge
                                                    MouseArea {
                                                        id: copyTopMa
                                                        anchors { fill: parent; margins: -4 }
                                                        hoverEnabled: true
                                                        onClicked: {
                                                            var n = modelData.notifications[0]
                                                            var textToCopy = (n.summary ? n.summary + "\n" : "") + (n.body ?? "")
                                                            Quickshell.execDetached(["bash", "-c", "printf '%s' " + JSON.stringify(textToCopy) + " | wl-copy"])
                                                        }
                                                    }
                                                }

                                                Text {
                                                    visible: modelData.notifications.length > 1
                                                    text: groupCol.expanded ? "󰅃" : "󰅀"
                                                    color: Theme.surfaceTextVariant; font.pointSize: Theme.titleSmall
                                                    MouseArea { anchors.fill: parent; onClicked: groupCol.expanded = !groupCol.expanded }
                                                }

                                                Text {
                                                    text: "✕"; color: Theme.error; font.pointSize: Theme.labelLarge; opacity: 0.7
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: modelData.notifications.forEach(n => NotificationService.dismiss(n))
                                                    }
                                                }
                                            }

                                            Text {
                                                text: modelData.notifications[0].summary; color: Theme.surfaceText
                                                font.family: Theme.fontFamily; font.pointSize: Theme.bodyMedium; font.bold: true
                                                Layout.fillWidth: true; wrapMode: Text.WordWrap
                                                visible: text !== ""
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: Theme.spacingXs
                                                visible: (modelData.notifications[0].body ?? "") !== ""
                                                property bool bodyExpanded: false

                                                Text {
                                                    id: topBodyText
                                                    text: modelData.notifications[0].body; color: Theme.surfaceTextVariant
                                                    font.family: Theme.fontFamily; font.pointSize: Theme.bodySmall
                                                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                                                    textFormat: Text.PlainText
                                                    maximumLineCount: parent.bodyExpanded ? 20 : 2
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    text: parent.bodyExpanded ? "Show less" : "Show more"
                                                    color: Theme.primary; opacity: 0.8
                                                    font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall
                                                    visible: topBodyText.lineCount > 2 || parent.bodyExpanded
                                                    MouseArea { anchors.fill: parent; onClicked: parent.parent.bodyExpanded = !parent.parent.bodyExpanded }
                                                }
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        visible: groupCol.expanded
                                        spacing: Theme.spacingSm
                                        Layout.leftMargin: Theme.spacingLg

                                        Repeater {
                                            model: modelData.notifications.slice(1)
                                            delegate: Rectangle {
                                                required property var modelData
                                                Layout.fillWidth: true
                                                implicitHeight: subItemLayout.implicitHeight + Theme.spacingMd
                                                radius: Theme.radiusMd
                                                color: subMa.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow

                                                MouseArea { id: subMa; anchors.fill: parent; hoverEnabled: true }

                                                ColumnLayout {
                                                    id: subItemLayout
                                                    anchors { fill: parent; margins: Theme.spacingSm; leftMargin: Theme.spacingMd }
                                                    spacing: 3

                                                    RowLayout {
                                                        Layout.fillWidth: true; spacing: Theme.spacingSm
                                                        Text {
                                                            text: modelData.time; color: Theme.surfaceTextDim
                                                            font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall
                                                            Layout.fillWidth: true
                                                        }
                                                        Text {
                                                            text: "󰆏"
                                                            color: copySubMa.containsMouse ? Theme.primary : Theme.surfaceTextDim
                                                            font.pointSize: Theme.labelLarge
                                                            MouseArea {
                                                                id: copySubMa
                                                                anchors { fill: parent; margins: -4 }
                                                                hoverEnabled: true
                                                                onClicked: {
                                                                    var textToCopy = (modelData.summary ? modelData.summary + "\n" : "") + (modelData.body ?? "")
                                                                    Quickshell.execDetached(["bash", "-c", "printf '%s' " + JSON.stringify(textToCopy) + " | wl-copy"])
                                                                }
                                                            }
                                                        }
                                                        Text {
                                                            text: "✕"; color: Theme.error; font.pointSize: Theme.labelLarge; opacity: 0.6
                                                            MouseArea { anchors.fill: parent; onClicked: NotificationService.dismiss(modelData) }
                                                        }
                                                    }

                                                    Text {
                                                        text: modelData.summary; color: Theme.surfaceText
                                                        font.family: Theme.fontFamily; font.pointSize: Theme.bodySmall; font.bold: true
                                                        Layout.fillWidth: true; elide: Text.ElideRight
                                                    }

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 1
                                                        visible: (modelData.body ?? "") !== ""
                                                        property bool subBodyExpanded: false

                                                        Text {
                                                            id: subBodyText
                                                            text: modelData.body; color: Theme.surfaceTextVariant
                                                            font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                                                            Layout.fillWidth: true; wrapMode: Text.WordWrap
                                                            textFormat: Text.PlainText
                                                            maximumLineCount: parent.subBodyExpanded ? 20 : 2
                                                            elide: Text.ElideRight
                                                        }

                                                        Text {
                                                            text: parent.subBodyExpanded ? "Show less" : "Show more"
                                                            color: Theme.primary; opacity: 0.8
                                                            font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall
                                                            visible: subBodyText.lineCount > 2 || parent.subBodyExpanded
                                                            MouseArea { anchors.fill: parent; onClicked: parent.parent.subBodyExpanded = !parent.parent.subBodyExpanded }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ══════════════════ TAB: DO NOT DISTURB ══════════════════
            Item {
                Layout.fillWidth: true
                implicitHeight: dndCol.implicitHeight
                visible: root.tab === "dnd"

                ColumnLayout {
                    id: dndCol
                    width: parent.width
                    spacing: Theme.spacingLg

                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: Theme.spacingXs
                            Text { text: "Do Not Disturb"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pointSize: Theme.bodyLarge; font.bold: true }
                            Text { text: "Silence all notification toasts"; color: Theme.surfaceTextDim; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 40; height: 22; radius: Theme.radiusFull
                            color: NotificationService.dndEnabled ? Theme.withAlpha(Theme.error, 0.3) : Theme.surfaceContainerHigh
                            Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                            Rectangle {
                                x: NotificationService.dndEnabled ? 20 : 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18; height: 18; radius: Theme.radiusFull
                                color: NotificationService.dndEnabled ? Theme.error : Theme.surfaceTextDim
                                Behavior on x { NumberAnimation { duration: Theme.motionMedium; easing.type: Theme.easingStandard } }
                            }
                            MouseArea { anchors.fill: parent; onClicked: NotificationService.dndEnabled = !NotificationService.dndEnabled }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outlineVariant }

                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: Theme.spacingXs
                            Text { text: "Scheduled"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pointSize: Theme.bodyLarge; font.bold: true }
                            Text { text: "Auto-enable on a time range"; color: Theme.surfaceTextDim; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 40; height: 22; radius: Theme.radiusFull
                            color: NotificationService.dndScheduled ? Theme.withAlpha(Theme.primary, 0.3) : Theme.surfaceContainerHigh
                            Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                            Rectangle {
                                x: NotificationService.dndScheduled ? 20 : 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18; height: 18; radius: Theme.radiusFull
                                color: NotificationService.dndScheduled ? Theme.primary : Theme.surfaceTextDim
                                Behavior on x { NumberAnimation { duration: Theme.motionMedium; easing.type: Theme.easingStandard } }
                            }
                            MouseArea { anchors.fill: parent; onClicked: NotificationService.dndScheduled = !NotificationService.dndScheduled }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: timeCol.implicitHeight + Theme.spacingLg
                        visible: NotificationService.dndScheduled
                        radius: Theme.radiusMd
                        color: Theme.surfaceContainerLow

                        ColumnLayout {
                            id: timeCol
                            anchors { fill: parent; margins: Theme.spacingMd }
                            spacing: Theme.spacingSm

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "From"; color: Theme.surfaceTextVariant; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; Layout.preferredWidth: 36 }
                                TimeSpinner { id: startHourSpinner; value: NotificationService.dndStartHour; min: 0; max: 23; onValueChanged: NotificationService.dndStartHour = startHourSpinner.value }
                                Text { text: ":"; color: Theme.surfaceTextVariant; font.pointSize: Theme.titleMedium; font.bold: true }
                                TimeSpinner { id: startMinSpinner; value: NotificationService.dndStartMin; min: 0; max: 59; step: 5; onValueChanged: NotificationService.dndStartMin = startMinSpinner.value }
                                Item { Layout.fillWidth: true }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "To"; color: Theme.surfaceTextVariant; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; Layout.preferredWidth: 36 }
                                TimeSpinner { id: endHourSpinner; value: NotificationService.dndEndHour; min: 0; max: 23; onValueChanged: NotificationService.dndEndHour = endHourSpinner.value }
                                Text { text: ":"; color: Theme.surfaceTextVariant; font.pointSize: Theme.titleMedium; font.bold: true }
                                TimeSpinner { id: endMinSpinner; value: NotificationService.dndEndMin; min: 0; max: 59; step: 5; onValueChanged: NotificationService.dndEndMin = endMinSpinner.value }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: {
                                        var sh = NotificationService.dndStartHour, sm = NotificationService.dndStartMin
                                        var eh = NotificationService.dndEndHour, em = NotificationService.dndEndMin
                                        var pad = n => String(n).padStart(2,"0")
                                        return pad(sh)+":"+pad(sm)+" – "+pad(eh)+":"+pad(em)
                                    }
                                    color: Theme.surfaceTextDim; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                                }
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            if (NotificationService.dndActive) return "󰂛  Notifications are silenced"
                            if (NotificationService.dndScheduled) return "󰂚  Active outside scheduled hours"
                            return "󰂚  Notifications are active"
                        }
                        color: NotificationService.dndActive ? Theme.error : Theme.surfaceTextDim
                        font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                    }
                }
            }

            // ══════════════════ TAB: APP FILTERS ══════════════════
            Item {
                Layout.fillWidth: true
                implicitHeight: filtersCol.implicitHeight
                visible: root.tab === "filters"

                ColumnLayout {
                    id: filtersCol
                    width: parent.width
                    spacing: Theme.spacingMd

                    Text {
                        text: "Silenced apps — notifications from these apps are dropped"
                        color: Theme.surfaceTextDim; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                        wrapMode: Text.WordWrap; Layout.fillWidth: true
                    }

                    Item {
                        Layout.fillWidth: true; implicitHeight: 48
                        visible: NotificationService.filteredApps.length === 0
                        Text {
                            anchors.centerIn: parent
                            text: "No apps silenced\nClick 󰈈 on a notification to silence its app"
                            color: Theme.surfaceTextDim; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        implicitHeight: Math.min(filterListCol.implicitHeight, 360)
                        contentHeight: filterListCol.implicitHeight
                        clip: true
                        visible: NotificationService.filteredApps.length > 0

                        ColumnLayout {
                            id: filterListCol
                            width: parent.width
                            spacing: Theme.spacingXs

                            Repeater {
                                model: NotificationService.filteredApps

                                delegate: Rectangle {
                                    required property string modelData
                                    required property int    index
                                    Layout.fillWidth: true
                                    implicitHeight: 36
                                    radius: Theme.radiusMd
                                    color: filterRowMa.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: Theme.spacingMd; rightMargin: Theme.spacingSm }
                                        spacing: Theme.spacingSm

                                        Text { text: "󰈈"; color: Theme.warning; font.pointSize: Theme.titleSmall }
                                        Text {
                                            text: modelData
                                            color: Theme.surfaceText; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                                            Layout.fillWidth: true; elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            implicitWidth: unsilenceLbl.implicitWidth + Theme.spacingMd; implicitHeight: 22
                                            radius: Theme.radiusSm
                                            color: unsilenceMa.containsMouse ? Theme.withAlpha(Theme.primary, 0.2) : Theme.withAlpha(Theme.primary, 0.1)
                                            Text { id: unsilenceLbl; anchors.centerIn: parent; text: "allow"; color: Theme.primary; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge }
                                            MouseArea { id: unsilenceMa; anchors.fill: parent; hoverEnabled: true; onClicked: NotificationService.unfilterApp(modelData) }
                                        }
                                    }

                                    MouseArea {
                                        id: filterRowMa; anchors.fill: parent; hoverEnabled: true
                                        propagateComposedEvents: true
                                        onClicked: mouse => mouse.accepted = false
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Tip: tap 󰈈 next to any notification to silence that app"
                        color: Theme.surfaceTextDim; font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall
                    }
                }
            }
        }
    }
}
