import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Notification center — three-tab panel: Notifications | Do Not Disturb | App Filters
PopupWindow {
    id: root

    implicitWidth:  400
    implicitHeight: Math.min(mainCol.implicitHeight + 24, 640)
    color: "transparent"

    // Tab: "notifs" | "dnd" | "filters"
    property string tab: "notifs"

    onVisibleChanged: {
        if (visible) {
            NotificationService.markAllRead()
            tab = "notifs"
        }
    }

    // ── Card background ───────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: 8
        color: "#f00d1117"
        border.color: "#335bcefa"
        border.width: 1
        clip: true

        // Top glow
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 1; color: "#220df0ff"
        }

        ColumnLayout {
            id: mainCol
            anchors { fill: parent; margins: 12 }
            spacing: 8

            // ── Tab bar ───────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

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
                        height: 26
                        color:        active ? "#220df0ff" : "transparent"
                        border.color: active ? "#440df0ff" : "transparent"
                        border.width: 1
                        radius: 3
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: active ? "#0df0ff" : "#7984a4"
                            font.family: Theme.fontFamily
                            font.pointSize: 7
                            font.bold: active
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.tab = modelData.id
                        }
                    }
                }

                // DnD quick-toggle pill (always visible, top-right)
                Rectangle {
                    implicitWidth:  dndPillLbl.implicitWidth + 14
                    implicitHeight: 22
                    radius: 11
                    color:        NotificationService.dndActive ? "#33ff416c" : "#110d1117"
                    border.color: NotificationService.dndActive ? "#88ff416c" : "#33ffffff"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: dndPillLbl
                        anchors.centerIn: parent
                        text: NotificationService.dndActive ? "DnD ON" : "DnD OFF"
                        color: NotificationService.dndActive ? "#ff416c" : "#555e7a"
                        font.family: Theme.fontFamily; font.pointSize: 6; font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: NotificationService.dndEnabled = !NotificationService.dndEnabled
                    }
                }

                // Close
                Text {
                    text: "✕"; color: "#7984a4"; font.pointSize: 9
                    leftPadding: 8
                    MouseArea { anchors.fill: parent; onClicked: root.visible = false }
                }
            }

            // Divider
            Rectangle { Layout.fillWidth: true; height: 1; color: "#1a5bcefa" }

            // ══════════════════════════════════════════════════════════════════
            // TAB: NOTIFICATIONS
            // ══════════════════════════════════════════════════════════════════
            Item {
                Layout.fillWidth: true
                implicitHeight: notifsCol.implicitHeight
                visible: root.tab === "notifs"

                ColumnLayout {
                    id: notifsCol
                    width: parent.width
                    spacing: 6

                    // Toolbar
                    RowLayout {
                        Layout.fillWidth: true

                        // Snoozed count badge
                        Rectangle {
                            visible: NotificationService.snoozed.length > 0
                            implicitWidth:  snoozeBadge.implicitWidth + 14
                            implicitHeight: 20; radius: 3
                            color: "#110df0ff"; border.color: "#330df0ff"; border.width: 1
                            Text {
                                id: snoozeBadge
                                anchors.centerIn: parent
                                text: "󰒲 " + NotificationService.snoozed.length + " snoozed"
                                color: "#7984a4"; font.family: Theme.fontFamily; font.pointSize: 6
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            visible: (NotificationService.notifications?.length ?? 0) > 0
                            implicitWidth: clearAllLbl.implicitWidth + 14; implicitHeight: 20
                            radius: 2; color: clearAllMa.containsMouse ? "#33ff416c" : "transparent"
                            border.color: "#55ff416c"; border.width: 1
                            Text {
                                id: clearAllLbl; anchors.centerIn: parent
                                text: "Clear all"; color: "#ff416c"
                                font.family: Theme.fontFamily; font.pointSize: 7
                            }
                            MouseArea {
                                id: clearAllMa; anchors.fill: parent; hoverEnabled: true
                                onClicked: NotificationService.clearAll()
                            }
                        }
                    }

                    // Empty state
                    Item {
                        Layout.fillWidth: true; implicitHeight: 60
                        visible: (NotificationService.notifications?.length ?? 0) === 0
                        Text {
                            anchors.centerIn: parent
                            text: NotificationService.dndActive
                                ? "󰂛  Do not disturb is on"
                                : "No notifications"
                            color: "#555e7a"; font.family: Theme.fontFamily; font.pointSize: 8
                        }
                    }

                    // Notification list
                    Flickable {
                        Layout.fillWidth: true
                        implicitHeight: Math.min(notifListCol.implicitHeight, 460)
                        contentHeight:  notifListCol.implicitHeight
                        clip: true
                        visible: (NotificationService.notifications?.length ?? 0) > 0

                        ColumnLayout {
                            id: notifListCol
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: NotificationService.notifications ?? []

                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight:   itemLayout.implicitHeight + 16
                                    radius: 4
                                    color:        itemMa.containsMouse ? "#1a5bcefa" : "#0d5bcefa"
                                    border.color: "#1a5bcefa"; border.width: 1
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    // Urgency stripe
                                    Rectangle {
                                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 1 }
                                        width: 2; radius: 2
                                        color: {
                                            var u = modelData.urgency ?? 1
                                            if (u === 2) return "#ff0000"
                                            if (u === 0) return "#555e7a"
                                            return "#0df0ff"
                                        }
                                    }

                                    ColumnLayout {
                                        id: itemLayout
                                        anchors { fill: parent; margins: 8; leftMargin: 14 }
                                        spacing: 3

                                        // Header row
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 6

                                            Text {
                                                text: modelData.appName; color: "#7984a4"
                                                font.family: Theme.fontFamily; font.pointSize: 7
                                                Layout.fillWidth: true; elide: Text.ElideRight
                                            }
                                            Text {
                                                text: modelData.time; color: "#444d62"
                                                font.family: Theme.fontFamily; font.pointSize: 7
                                            }
                                            // Filter this app
                                            Text {
                                                text: "󰈈"; color: filterAppMa.containsMouse ? "#ffcc00" : "#444d62"
                                                font.pointSize: 7
                                                Behavior on color { ColorAnimation { duration: 100 } }
                                                MouseArea {
                                                    id: filterAppMa; anchors { fill: parent; margins: -4 }
                                                    hoverEnabled: true
                                                    onClicked: {
                                                        NotificationService.filterApp(modelData.appName)
                                                        NotificationService.dismiss(modelData)
                                                    }
                                                }
                                            }
                                            // Dismiss
                                            Text {
                                                text: "✕"; color: "#555e7a"; font.pointSize: 7
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: NotificationService.dismiss(modelData)
                                                }
                                            }
                                        }

                                        // Summary
                                        Text {
                                            text: modelData.summary; color: "#c8d2e0"
                                            font.family: Theme.fontFamily; font.pointSize: 8; font.bold: true
                                            Layout.fillWidth: true; wrapMode: Text.WordWrap
                                            visible: text !== ""
                                        }

                                        // Body
                                        Text {
                                            text: modelData.body; color: "#7984a4"
                                            font.family: Theme.fontFamily; font.pointSize: 7
                                            Layout.fillWidth: true; wrapMode: Text.WordWrap
                                            textFormat: Text.PlainText; maximumLineCount: 4
                                            elide: Text.ElideRight; visible: text !== ""
                                        }

                                        // Action buttons
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 4
                                            visible: (modelData.actions?.length ?? 0) > 0

                                            // Capture outer notif so inner Repeater can reference it
                                            property var notif: modelData

                                            Repeater {
                                                model: modelData.actions ?? []
                                                delegate: Rectangle {
                                                    required property var modelData
                                                    implicitWidth:  actLbl.implicitWidth + 14; implicitHeight: 20
                                                    radius: 3
                                                    color: actMa.containsMouse ? "#220df0ff" : "#110d1117"
                                                    border.color: "#330df0ff"; border.width: 1
                                                    Behavior on color { ColorAnimation { duration: 100 } }
                                                    Text {
                                                        id: actLbl; anchors.centerIn: parent
                                                        text: modelData.label; color: "#0df0ff"
                                                        font.family: Theme.fontFamily; font.pointSize: 7
                                                    }
                                                    MouseArea {
                                                        id: actMa; anchors.fill: parent; hoverEnabled: true
                                                        onClicked: NotificationService.invokeAction(
                                                            parent.parent.parent.notif, modelData.id)
                                                    }
                                                }
                                            }

                                            // Snooze from center too
                                            Rectangle {
                                                implicitWidth: snoozeCenterLbl.implicitWidth + 14; implicitHeight: 20
                                                radius: 3; color: snoozeCenterMa.containsMouse ? "#110d1117" : "transparent"
                                                border.color: "#225bcefa"; border.width: 1
                                                Text {
                                                    id: snoozeCenterLbl; anchors.centerIn: parent
                                                    text: "󰒲 snooze"; color: "#555e7a"
                                                    font.family: Theme.fontFamily; font.pointSize: 7
                                                }
                                                MouseArea {
                                                    id: snoozeCenterMa; anchors.fill: parent; hoverEnabled: true
                                                    onClicked: NotificationService.snooze(parent.parent.notif, 15)
                                                }
                                            }

                                            Item { Layout.fillWidth: true }
                                        }
                                    }

                                    MouseArea {
                                        id: itemMa; anchors.fill: parent; hoverEnabled: true
                                        propagateComposedEvents: true
                                        onClicked: mouse => mouse.accepted = false
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ══════════════════════════════════════════════════════════════════
            // TAB: DO NOT DISTURB
            // ══════════════════════════════════════════════════════════════════
            Item {
                Layout.fillWidth: true
                implicitHeight: dndCol.implicitHeight
                visible: root.tab === "dnd"

                ColumnLayout {
                    id: dndCol
                    width: parent.width
                    spacing: 12

                    // Manual DnD toggle
                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: "Do Not Disturb"
                                color: "#d8e0f0"; font.family: Theme.fontFamily
                                font.pointSize: 9; font.bold: true
                            }
                            Text {
                                text: "Silence all notification toasts"
                                color: "#555e7a"; font.family: Theme.fontFamily; font.pointSize: 7
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Toggle switch
                        Rectangle {
                            width: 44; height: 24; radius: 12
                            color: NotificationService.dndEnabled ? "#33ff416c" : "#1a1e2e"
                            border.color: NotificationService.dndEnabled ? "#88ff416c" : "#33ffffff"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Rectangle {
                                x: NotificationService.dndEnabled ? 22 : 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20; height: 20; radius: 10
                                color: NotificationService.dndEnabled ? "#ff416c" : "#555e7a"
                                Behavior on x     { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation  { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: NotificationService.dndEnabled = !NotificationService.dndEnabled
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#1a5bcefa" }

                    // Scheduled DnD toggle
                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: "Scheduled"
                                color: "#d8e0f0"; font.family: Theme.fontFamily
                                font.pointSize: 9; font.bold: true
                            }
                            Text {
                                text: "Auto-enable on a time range"
                                color: "#555e7a"; font.family: Theme.fontFamily; font.pointSize: 7
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 44; height: 24; radius: 12
                            color: NotificationService.dndScheduled ? "#330df0ff" : "#1a1e2e"
                            border.color: NotificationService.dndScheduled ? "#660df0ff" : "#33ffffff"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Rectangle {
                                x: NotificationService.dndScheduled ? 22 : 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20; height: 20; radius: 10
                                color: NotificationService.dndScheduled ? "#0df0ff" : "#555e7a"
                                Behavior on x     { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation  { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: NotificationService.dndScheduled = !NotificationService.dndScheduled
                            }
                        }
                    }

                    // Time range picker (shown when scheduled is on)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: timeCol.implicitHeight + 16
                        visible: NotificationService.dndScheduled
                        radius: 5
                        color: "#0d5bcefa"
                        border.color: "#1a5bcefa"; border.width: 1

                        ColumnLayout {
                            id: timeCol
                            anchors { fill: parent; margins: 10 }
                            spacing: 8

                            // From
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "From"
                                    color: "#7984a4"; font.family: Theme.fontFamily; font.pointSize: 8
                                    Layout.preferredWidth: 36
                                }
                                TimeSpinner {
                                    id: startHourSpinner
                                    value: NotificationService.dndStartHour
                                    min: 0; max: 23
                                    onValueChanged: NotificationService.dndStartHour = startHourSpinner.value
                                }
                                Text { text: ":"; color: "#7984a4"; font.pointSize: 10; font.bold: true }
                                TimeSpinner {
                                    id: startMinSpinner
                                    value: NotificationService.dndStartMin
                                    min: 0; max: 59; step: 5
                                    onValueChanged: NotificationService.dndStartMin = startMinSpinner.value
                                }
                                Item { Layout.fillWidth: true }
                            }

                            // To
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "To"
                                    color: "#7984a4"; font.family: Theme.fontFamily; font.pointSize: 8
                                    Layout.preferredWidth: 36
                                }
                                TimeSpinner {
                                    id: endHourSpinner
                                    value: NotificationService.dndEndHour
                                    min: 0; max: 23
                                    onValueChanged: NotificationService.dndEndHour = endHourSpinner.value
                                }
                                Text { text: ":"; color: "#7984a4"; font.pointSize: 10; font.bold: true }
                                TimeSpinner {
                                    id: endMinSpinner
                                    value: NotificationService.dndEndMin
                                    min: 0; max: 59; step: 5
                                    onValueChanged: NotificationService.dndEndMin = endMinSpinner.value
                                }
                                Item { Layout.fillWidth: true }

                                Text {
                                    text: {
                                        var sh = NotificationService.dndStartHour
                                        var sm = NotificationService.dndStartMin
                                        var eh = NotificationService.dndEndHour
                                        var em = NotificationService.dndEndMin
                                        var pad = n => String(n).padStart(2,"0")
                                        return pad(sh)+":"+pad(sm)+" – "+pad(eh)+":"+pad(em)
                                    }
                                    color: "#444d62"; font.family: Theme.fontFamily; font.pointSize: 7
                                }
                            }
                        }
                    }

                    // Status summary
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            if (NotificationService.dndActive)
                                return "󰂛  Notifications are silenced"
                            if (NotificationService.dndScheduled)
                                return "󰂚  Active outside scheduled hours"
                            return "󰂚  Notifications are active"
                        }
                        color: NotificationService.dndActive ? "#ff416c" : "#555e7a"
                        font.family: Theme.fontFamily; font.pointSize: 7
                    }
                }
            }

            // ══════════════════════════════════════════════════════════════════
            // TAB: APP FILTERS
            // ══════════════════════════════════════════════════════════════════
            Item {
                Layout.fillWidth: true
                implicitHeight: filtersCol.implicitHeight
                visible: root.tab === "filters"

                ColumnLayout {
                    id: filtersCol
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Silenced apps — notifications from these apps are dropped"
                        color: "#555e7a"; font.family: Theme.fontFamily; font.pointSize: 7
                        wrapMode: Text.WordWrap; Layout.fillWidth: true
                    }

                    // Empty state
                    Item {
                        Layout.fillWidth: true; implicitHeight: 48
                        visible: NotificationService.filteredApps.length === 0
                        Text {
                            anchors.centerIn: parent
                            text: "No apps silenced\nClick 󰈈 on a notification to silence its app"
                            color: "#444d62"; font.family: Theme.fontFamily; font.pointSize: 7
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    // Filtered apps list
                    Flickable {
                        Layout.fillWidth: true
                        implicitHeight: Math.min(filterListCol.implicitHeight, 360)
                        contentHeight: filterListCol.implicitHeight
                        clip: true
                        visible: NotificationService.filteredApps.length > 0

                        ColumnLayout {
                            id: filterListCol
                            width: parent.width
                            spacing: 4

                            Repeater {
                                model: NotificationService.filteredApps

                                delegate: Rectangle {
                                    required property string modelData
                                    required property int    index
                                    Layout.fillWidth: true
                                    implicitHeight: 32
                                    radius: 4
                                    color: filterRowMa.containsMouse ? "#1a5bcefa" : "#0d5bcefa"
                                    border.color: "#1a5bcefa"; border.width: 1
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 12; rightMargin: 10 }
                                        spacing: 8

                                        Text {
                                            text: "󰈈"
                                            color: "#ffcc00"; font.pointSize: 9
                                        }

                                        Text {
                                            text: modelData
                                            color: "#c8d2e0"; font.family: Theme.fontFamily; font.pointSize: 8
                                            Layout.fillWidth: true; elide: Text.ElideRight
                                        }

                                        // Unsilence button
                                        Rectangle {
                                            implicitWidth: unsilenceLbl.implicitWidth + 12; implicitHeight: 20
                                            radius: 3
                                            color: unsilenceMa.containsMouse ? "#220df0ff" : "transparent"
                                            border.color: "#330df0ff"; border.width: 1

                                            Text {
                                                id: unsilenceLbl; anchors.centerIn: parent
                                                text: "allow"; color: "#0df0ff"
                                                font.family: Theme.fontFamily; font.pointSize: 7
                                            }
                                            MouseArea {
                                                id: unsilenceMa; anchors.fill: parent; hoverEnabled: true
                                                onClicked: NotificationService.unfilterApp(modelData)
                                            }
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

                    // Tip
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Tip: tap 󰈈 next to any notification to silence that app"
                        color: "#333a4d"; font.family: Theme.fontFamily; font.pointSize: 6
                    }
                }
            }
        }
    }
}


