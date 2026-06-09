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
                            spacing: 12 // Increased spacing between groups

                            Repeater {
                                model: NotificationService.groupedNotifications

                                delegate: ColumnLayout {
                                    id: groupCol
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 6 // Spacing between header and expanded items

                                    property bool expanded: false

                                    // Stack Header / Top Notification
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: topItemLayout.implicitHeight + 16
                                        radius: 6
                                        color: groupMa.containsMouse ? "#1e2233" : "#161925"
                                        border.color: groupMa.containsMouse ? "#440df0ff" : "#1a5bcefa"
                                        border.width: 1
                                        
                                        MouseArea {
                                            id: groupMa; anchors.fill: parent; hoverEnabled: true
                                            onClicked: {
                                                if (modelData.notifications.length > 1) {
                                                    groupCol.expanded = !groupCol.expanded
                                                }
                                            }
                                        }

                                        // Stack visual effect (double stack for more depth)
                                        Rectangle {
                                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 6; bottomMargin: -6 }
                                            height: 6; radius: 6; z: -2
                                            color: "#0a0df0ff"; border.color: "#125bcefa"; border.width: 1
                                            visible: modelData.notifications.length > 1 && !groupCol.expanded
                                        }
                                        Rectangle {
                                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 3; bottomMargin: -3 }
                                            height: 6; radius: 6; z: -1
                                            color: "#0d5bcefa"; border.color: "#1a5bcefa"; border.width: 1
                                            visible: modelData.notifications.length > 1 && !groupCol.expanded
                                        }

                                        // Urgency stripe (from the first notif)
                                        Rectangle {
                                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 1 }
                                            width: 3; radius: 3
                                            color: {
                                                var u = modelData.notifications[0].urgency ?? 1
                                                if (u === 2) return Theme.red
                                                if (u === 0) return Theme.textDimmer
                                                return Theme.cyan
                                            }
                                        }

                                        ColumnLayout {
                                            id: topItemLayout
                                            anchors { fill: parent; margins: 10; leftMargin: 16 }
                                            spacing: 4

                                            // Header row
                                            RowLayout {
                                                Layout.fillWidth: true; spacing: 8

                                                Text {
                                                    text: modelData.appName; color: Theme.textDim
                                                    font.family: Theme.fontFamily; font.pointSize: 7; font.bold: true
                                                    Layout.fillWidth: true; elide: Text.ElideRight
                                                }
                                                
                                                // Stack count badge
                                                Rectangle {
                                                    visible: modelData.notifications.length > 1
                                                    implicitWidth: stackCount.implicitWidth + 10
                                                    implicitHeight: 16; radius: 8
                                                    color: "#220df0ff"; border.color: "#440df0ff"; border.width: 1
                                                    Text {
                                                        id: stackCount
                                                        anchors.centerIn: parent
                                                        text: modelData.notifications.length
                                                        color: Theme.cyan; font.family: Theme.fontFamily; font.pointSize: 7; font.bold: true
                                                    }
                                                }

                                                Text {
                                                    text: modelData.notifications[0].time; color: Theme.textDimmer
                                                    font.family: Theme.fontFamily; font.pointSize: 7
                                                }

                                                // Copy button
                                                Text {
                                                    text: "󰆏"
                                                    color: copyTopMa.containsMouse ? Theme.cyan : Theme.textDimmer
                                                    font.pointSize: 8
                                                    Behavior on color { ColorAnimation { duration: 100 } }
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
                                                
                                                // Expand/Collapse Stack
                                                Text {
                                                    visible: modelData.notifications.length > 1
                                                    text: groupCol.expanded ? "󰅃" : "󰅀"
                                                    color: Theme.textDim; font.pointSize: 9
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: groupCol.expanded = !groupCol.expanded
                                                    }
                                                }

                                                // Dismiss Group
                                                Text {
                                                    text: "✕"; color: Theme.red; font.pointSize: 8; opacity: 0.7
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: {
                                                            modelData.notifications.forEach(n => NotificationService.dismiss(n))
                                                        }
                                                    }
                                                }
                                            }

                                            // Summary
                                            Text {
                                                text: modelData.notifications[0].summary; color: Theme.textPrimary
                                                font.family: Theme.fontFamily; font.pointSize: 8; font.bold: true
                                                Layout.fillWidth: true; wrapMode: Text.WordWrap
                                                visible: text !== ""
                                            }

                                            // Body
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                visible: (modelData.notifications[0].body ?? "") !== ""
                                                
                                                property bool bodyExpanded: false

                                                Text {
                                                    id: topBodyText
                                                    text: modelData.notifications[0].body; color: Theme.textDim
                                                    font.family: Theme.fontFamily; font.pointSize: 7.5
                                                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                                                    textFormat: Text.PlainText
                                                    maximumLineCount: parent.bodyExpanded ? 20 : 2
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    text: parent.bodyExpanded ? "Show less" : "Show more"
                                                    color: Theme.cyan; opacity: 0.8
                                                    font.family: Theme.fontFamily; font.pointSize: 6.5
                                                    visible: topBodyText.lineCount > 2 || parent.bodyExpanded
                                                    
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: parent.parent.bodyExpanded = !parent.parent.bodyExpanded
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Expanded items
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        visible: groupCol.expanded
                                        spacing: 6
                                        Layout.leftMargin: 12

                                        Repeater {
                                            model: modelData.notifications.slice(1)
                                            delegate: Rectangle {
                                                required property var modelData
                                                Layout.fillWidth: true
                                                implicitHeight: subItemLayout.implicitHeight + 14
                                                radius: 6
                                                color: subMa.containsMouse ? "#1a1e2e" : "#111420"
                                                border.color: "#1a5bcefa"; border.width: 1

                                                MouseArea {
                                                    id: subMa; anchors.fill: parent; hoverEnabled: true
                                                }

                                                ColumnLayout {
                                                    id: subItemLayout
                                                    anchors { fill: parent; margins: 8; leftMargin: 12 }
                                                    spacing: 3

                                                    RowLayout {
                                                        Layout.fillWidth: true; spacing: 6
                                                        Text {
                                                            text: modelData.time; color: Theme.textDimmer
                                                            font.family: Theme.fontFamily; font.pointSize: 6.5
                                                            Layout.fillWidth: true
                                                        }
                                                        
                                                        // Copy button
                                                        Text {
                                                            text: "󰆏"
                                                            color: copySubMa.containsMouse ? Theme.cyan : Theme.textDimmer
                                                            font.pointSize: 7
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
                                                            text: "✕"; color: Theme.red; font.pointSize: 7; opacity: 0.6
                                                            MouseArea {
                                                                anchors.fill: parent
                                                                onClicked: NotificationService.dismiss(modelData)
                                                            }
                                                        }
                                                    }

                                                    Text {
                                                        text: modelData.summary; color: Theme.textPrimary
                                                        font.family: Theme.fontFamily; font.pointSize: 7.5; font.bold: true
                                                        Layout.fillWidth: true; elide: Text.ElideRight
                                                    }

                                                    // Body with expansion
                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 1
                                                        visible: (modelData.body ?? "") !== ""
                                                        
                                                        property bool subBodyExpanded: false

                                                        Text {
                                                            id: subBodyText
                                                            text: modelData.body; color: Theme.textDim
                                                            font.family: Theme.fontFamily; font.pointSize: 7
                                                            Layout.fillWidth: true; wrapMode: Text.WordWrap
                                                            textFormat: Text.PlainText
                                                            maximumLineCount: parent.subBodyExpanded ? 20 : 2
                                                            elide: Text.ElideRight
                                                        }

                                                        Text {
                                                            text: parent.subBodyExpanded ? "Show less" : "Show more"
                                                            color: Theme.cyan; opacity: 0.8
                                                            font.family: Theme.fontFamily; font.pointSize: 6
                                                            visible: subBodyText.lineCount > 2 || parent.subBodyExpanded
                                                            
                                                            MouseArea {
                                                                anchors.fill: parent
                                                                onClicked: parent.parent.subBodyExpanded = !parent.parent.subBodyExpanded
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


