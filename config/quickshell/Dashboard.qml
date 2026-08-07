import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Dashboard — unified Notifications / Calendar / Controls panel.
// Replaces the old three separate popups (NotificationCenter, CalendarPopup,
// ControlCenter). All three bar triggers open THIS panel, just landing on a
// different rail section — so switching context doesn't mean closing one
// popup and opening another, it's a single click on the rail.
PopupWindow {
    id: root

    implicitWidth:  640
    implicitHeight: 560
    color: "transparent"

    // "notifs" | "calendar" | "controls"
    property string tab: "notifs"
    property string notifSubTab: "list"   // "list" | "dnd" | "filters"  (nested, Notifications only)
    property bool   showControlSettings: false

    function openTab(t) {
        tab = t
        visible = true
    }

    // Settings sub-view toggle (called from the MODULE VISIBILITY list)
    function toggleSetting(key) {
        if (key === "workspaces") SettingsService.showWorkspaces = !SettingsService.showWorkspaces
        else if (key === "weather") SettingsService.showWeather = !SettingsService.showWeather
        else if (key === "temp") SettingsService.showTemp = !SettingsService.showTemp
        else if (key === "storage") SettingsService.showStorage = !SettingsService.showStorage
        else if (key === "memory") SettingsService.showMemory = !SettingsService.showMemory
        else if (key === "cpu") SettingsService.showCpu = !SettingsService.showCpu
        else if (key === "battery") SettingsService.showBattery = !SettingsService.showBattery
        else if (key === "network") SettingsService.showNetwork = !SettingsService.showNetwork
        else if (key === "media") SettingsService.showMedia = !SettingsService.showMedia
        else if (key === "stats") SettingsService.showStats = !SettingsService.showStats
        else if (key === "dashboardPosition") {
            var pos = SettingsService.dashboardPosition
            SettingsService.dashboardPosition = pos === "left" ? "center" : pos === "center" ? "right" : "left"
        }
    }

    onVisibleChanged: {
        if (visible) {
            if (tab === "notifs") NotificationService.markAllRead()
            notifSubTab = "list"
            showControlSettings = false
            volPoll.running = true
            brightPoll.running = true
            updateToday()
        }
    }

    // ── Calendar state ──────────────────────────────────────────────────
    property int displayYear:  new Date().getFullYear()
    property int displayMonth: new Date().getMonth()
    property int todayDay:     new Date().getDate()
    property int todayMonth:   new Date().getMonth()
    property int todayYear:    new Date().getFullYear()

    readonly property var monthNames: ["January","February","March","April","May","June",
                                       "July","August","September","October","November","December"]
    readonly property var dayNames: ["Su","Mo","Tu","We","Th","Fr","Sa"]

    function updateToday() {
        const now = new Date()
        root.todayDay = now.getDate(); root.todayMonth = now.getMonth(); root.todayYear = now.getFullYear()
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.updateToday() }
    function daysInMonth(year, month) { return new Date(year, month + 1, 0).getDate() }
    function firstDayOfMonth(year, month) { return new Date(year, month, 1).getDay() }
    function prevMonth() { if (displayMonth === 0) { displayMonth = 11; displayYear-- } else displayMonth-- }
    function nextMonth() { if (displayMonth === 11) { displayMonth = 0; displayYear++ } else displayMonth++ }

    // ── Controls state ───────────────────────────────────────────────────
    property int volume: 0
    property bool muted: false
    property int brightness: 100

    // ── At-a-glance state (for coloring) ──────────────────────────────────
    property int tempC: 0
    property int batteryCap: 100

    // ── Storage card cycling state ─────────────────────────────────────────
    property int storageIndex: 0
    property var storageLines: []

    function rate(bps) {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + " MB/s"
        if (bps >= 1024) return Math.round(bps / 1024) + " KB/s"
        return bps + " B/s"
    }

    Process {
        id: volPoll
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                root.muted = data.includes("[MUTED]")
                var m = data.match(/[\d.]+/)
                if (m) root.volume = Math.round(parseFloat(m[0]) * 100)
            }
        }
    }
    Process {
        id: brightPoll
        command: ["bash", "-c", "brightnessctl get 2>/dev/null; brightnessctl max 2>/dev/null"]
        running: false
        property int cur: 0
        property int max: 100
        property int lineNum: 0
        stdout: SplitParser {
            onRead: data => {
                var v = parseInt(data.trim())
                if (!isNaN(v)) {
                    if (brightPoll.lineNum === 0) brightPoll.cur = v
                    else root.brightness = Math.round((brightPoll.cur / v) * 100)
                    brightPoll.lineNum++
                }
            }
        }
        onRunningChanged: if (running) lineNum = 0
    }

    // ─────────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.spacingXs
        radius: Theme.radiusXl
        color: Theme.cardColor()
        border.color: Theme.cardBorder()
        border.width: 1
        clip: true

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── Rail ─────────────────────────────────────────────────────
            ColumnLayout {
                Layout.preferredWidth: 60
                Layout.fillHeight: true
                Layout.topMargin: Theme.spacingLg
                Layout.bottomMargin: Theme.spacingLg
                spacing: Theme.spacingSm

                Item { Layout.preferredHeight: Theme.spacingXs }

                Rectangle {
                    id: railNotifs
                    Layout.alignment: Qt.AlignHCenter
                    readonly property bool active: root.tab === "notifs"
                    readonly property int unread: NotificationService.unreadCount ?? 0
                    width: 40; height: 40; radius: Theme.radiusMd
                    color: active ? Theme.withAlpha(Theme.primary, 0.16)
                         : (railNotifsMa.containsMouse ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰂚"
                        color: railNotifs.active ? Theme.primary : Theme.surfaceTextVariant
                        font.family: Theme.fontFamily; font.pointSize: Theme.titleMedium
                    }
                    Rectangle {
                        visible: railNotifs.unread > 0
                        anchors { top: parent.top; right: parent.right; topMargin: 2; rightMargin: 2 }
                        width: 8; height: 8; radius: 4
                        color: Theme.warning
                    }
                    MouseArea { id: railNotifsMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.tab = "notifs" }
                }

                Rectangle {
                    id: railCalendar
                    Layout.alignment: Qt.AlignHCenter
                    readonly property bool active: root.tab === "calendar"
                    width: 40; height: 40; radius: Theme.radiusMd
                    color: active ? Theme.withAlpha(Theme.primary, 0.16)
                         : (railCalMa.containsMouse ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "\u{f133}"
                        color: railCalendar.active ? Theme.primary : Theme.surfaceTextVariant
                        font.family: Theme.fontFamily; font.pointSize: Theme.titleMedium
                    }
                    MouseArea { id: railCalMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.tab = "calendar" }
                }

                Rectangle {
                    id: railControls
                    Layout.alignment: Qt.AlignHCenter
                    readonly property bool active: root.tab === "controls"
                    width: 40; height: 40; radius: Theme.radiusMd
                    color: active ? Theme.withAlpha(Theme.primary, 0.16)
                         : (railCtrlMa.containsMouse ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰒓"
                        color: railControls.active ? Theme.primary : Theme.surfaceTextVariant
                        font.family: Theme.fontFamily; font.pointSize: Theme.titleMedium
                    }
                    MouseArea { id: railCtrlMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.tab = "controls" }
                }

                Rectangle {
                    id: railStats
                    Layout.alignment: Qt.AlignHCenter
                    readonly property bool active: root.tab === "stats"
                    width: 40; height: 40; radius: Theme.radiusMd
                    color: active ? Theme.withAlpha(Theme.primary, 0.16)
                         : (railStatsMa.containsMouse ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰻠"
                        color: railStats.active ? Theme.primary : Theme.surfaceTextVariant
                        font.family: Theme.fontFamily; font.pointSize: Theme.titleMedium
                    }
                    MouseArea { id: railStatsMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.tab = "stats" }
                }

                Item { Layout.fillHeight: true }

                // Always-visible DnD quick toggle at the foot of the rail
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 40; height: 40; radius: Theme.radiusMd
                    color: NotificationService.dndActive ? Theme.withAlpha(Theme.error, 0.18)
                         : (railDndMa.containsMouse ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                    Text {
                        anchors.centerIn: parent
                        text: NotificationService.dndActive ? "󰂛" : "󰂚"
                        color: NotificationService.dndActive ? Theme.error : Theme.surfaceTextDim
                        font.family: Theme.fontFamily; font.pointSize: Theme.titleSmall
                    }
                    MouseArea {
                        id: railDndMa; anchors.fill: parent; hoverEnabled: true
                        onClicked: NotificationService.dndEnabled = !NotificationService.dndEnabled
                    }
                }
            }

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.outlineVariant }

            // ── Content column ──────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Theme.spacingLg
                spacing: Theme.spacingMd

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSm

                    Text {
                        text: root.tab === "notifs" ? "Notifications" : root.tab === "calendar" ? "Calendar" : root.tab === "stats" ? "System Stats" : "Controls"
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.titleMedium
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    // Notifications: nested sub-tab strip (List / DnD / Filters)
                    RowLayout {
                        visible: root.tab === "notifs"
                        spacing: Theme.spacingXs
                        Repeater {
                            model: [
                                { id: "list",    label: "List" },
                                { id: "dnd",     label: "DnD" },
                                { id: "filters", label: "Filters" },
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool active: root.notifSubTab === modelData.id
                                implicitWidth: subLbl.implicitWidth + Theme.spacingMd
                                implicitHeight: 24
                                radius: Theme.radiusSm
                                color: active ? Theme.withAlpha(Theme.primary, 0.16) : "transparent"
                                Text {
                                    id: subLbl
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: active ? Theme.primary : Theme.surfaceTextVariant
                                    font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; font.bold: active
                                }
                                MouseArea { anchors.fill: parent; onClicked: root.notifSubTab = modelData.id }
                            }
                        }
                    }

                    // Controls: gear toggles the nested settings sub-view
                    Rectangle {
                        visible: root.tab === "controls"
                        width: 26; height: 26; radius: Theme.radiusSm
                        color: ctrlGearMa.containsMouse ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: root.showControlSettings ? "󰅖" : "󰒓"
                            color: Theme.surfaceTextVariant
                            font.family: Theme.fontFamily; font.pointSize: Theme.titleSmall
                        }
                        MouseArea { id: ctrlGearMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.showControlSettings = !root.showControlSettings }
                    }

                    Rectangle {
                        width: 26; height: 26; radius: Theme.radiusSm
                        color: closeMa.containsMouse ? Theme.withAlpha(Theme.error, 0.16) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: closeMa.containsMouse ? Theme.error : Theme.surfaceTextVariant
                            font.pointSize: Theme.labelLarge
                        }
                        MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.visible = false }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outlineVariant }

                // ══════════════════ SECTION CONTENT ══════════════════
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // ── NOTIFICATIONS ────────────────────────────────
                    Item {
                        anchors.fill: parent
                        visible: root.tab === "notifs"

                        // sub-tab: list
                        ColumnLayout {
                            anchors.fill: parent
                            visible: root.notifSubTab === "list"
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
                                Layout.fillWidth: true; Layout.fillHeight: true
                                visible: (NotificationService.notifications?.length ?? 0) === 0
                                Text {
                                    anchors.centerIn: parent
                                    text: NotificationService.dndActive ? "󰂛  Do not disturb is on" : "No notifications"
                                    color: Theme.surfaceTextDim; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                                }
                            }

                            Flickable {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                contentHeight: notifListCol.implicitHeight
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

                        // sub-tab: dnd
                        ColumnLayout {
                            anchors.fill: parent
                            visible: root.notifSubTab === "dnd"
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

                            Item { Layout.fillHeight: true }

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

                        // sub-tab: filters
                        ColumnLayout {
                            anchors.fill: parent
                            visible: root.notifSubTab === "filters"
                            spacing: Theme.spacingMd

                            Text {
                                text: "Silenced apps — notifications from these apps are dropped"
                                color: Theme.surfaceTextDim; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                                wrapMode: Text.WordWrap; Layout.fillWidth: true
                            }

                            Item {
                                Layout.fillWidth: true; Layout.fillHeight: true
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
                                Layout.fillHeight: true
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
                                            MouseArea { id: filterRowMa; anchors.fill: parent; hoverEnabled: true; propagateComposedEvents: true; onClicked: mouse => mouse.accepted = false }
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

                    // ── CALENDAR ──────────────────────────────────────
                    Item {
                        id: calendarSection
                        anchors.fill: parent
                        visible: root.tab === "calendar"

                        property string selectedDate: TodoService.today

                        ColumnLayout {
                            width: Math.min(parent.width, 320)
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Theme.spacingMd

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "‹"; color: Theme.primary; font.pointSize: Theme.titleLarge; font.bold: true
                                    MouseArea { anchors.fill: parent; onClicked: root.prevMonth() }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.monthNames[root.displayMonth] + "  " + root.displayYear
                                    color: Theme.surfaceText
                                    font.family: Theme.fontFamily; font.pointSize: Theme.bodyLarge; font.bold: true
                                }
                                Text {
                                    text: "›"; color: Theme.primary; font.pointSize: Theme.titleLarge; font.bold: true
                                    MouseArea { anchors.fill: parent; onClicked: root.nextMonth() }
                                }
                            }

                            Grid {
                                columns: 7
                                Layout.fillWidth: true
                                spacing: Theme.spacingXs

                                Repeater {
                                    model: root.dayNames
                                    delegate: Text {
                                        required property string modelData
                                        width: 320 / 7
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData
                                        color: Theme.surfaceTextDim
                                        font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; font.bold: true
                                    }
                                }
                                Repeater {
                                    model: root.firstDayOfMonth(root.displayYear, root.displayMonth)
                                    delegate: Item { width: 320 / 7; height: 32 }
                                }
                                Repeater {
                                    model: root.daysInMonth(root.displayYear, root.displayMonth)
                                    delegate: Rectangle {
                                        required property int index

                                        readonly property int day: index + 1
                                        readonly property bool isToday: day === root.todayDay
                                            && root.displayMonth === root.todayMonth
                                            && root.displayYear === root.todayYear
                                        readonly property bool isSelected: {
                                            var d = new Date(root.displayYear, root.displayMonth, day)
                                            return Qt.formatDate(d, "yyyy-MM-dd") === calendarSection.selectedDate
                                        }

                                        width: 320 / 7
                                        height: 32
                                        radius: Theme.radiusSm
                                        color: isSelected ? Theme.withAlpha(Theme.secondary, 0.2)
                                             : isToday ? Theme.withAlpha(Theme.primary, 0.18)
                                             : (dayMa.containsMouse ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : "transparent")

                                        Text {
                                            anchors.centerIn: parent
                                            text: day.toString()
                                            color: isSelected ? Theme.secondary
                                                 : isToday ? Theme.primary
                                                 : Theme.surfaceTextVariant
                                            font.family: Theme.fontFamily; font.pointSize: Theme.bodyMedium; font.bold: isToday || isSelected
                                        }
                                        MouseArea {
                                            id: dayMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                var d = new Date(root.displayYear, root.displayMonth, day)
                                                calendarSection.selectedDate = Qt.formatDate(d, "yyyy-MM-dd")
                                            }
                                        }
                                    }
                                }
                            }

                            // Todo list for selected date
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: todoListCol.implicitHeight + Theme.spacingMd
                                radius: Theme.radiusMd
                                color: Theme.surfaceContainerLow
                                visible: todoListCol.implicitHeight > 0

                                ColumnLayout {
                                    id: todoListCol
                                    anchors { fill: parent; margins: Theme.spacingMd }
                                    spacing: Theme.spacingXs
                                    width: parent.width

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingSm
                                        Text {
                                            text: "󰄲  Tasks for " + (function() {
                                                if (calendarSection.selectedDate === TodoService.today) return "Today"
                                                var d = new Date(calendarSection.selectedDate + "T12:00:00")
                                                return d.toLocaleDateString(Qt.locale(), "EEE, MMM d")
                                            })()
                                            color: Theme.surfaceText
                                            font.family: Theme.fontFamily
                                            font.pointSize: Theme.labelLarge
                                            font.bold: true
                                            Layout.fillWidth: true
                                        }
                                        Rectangle {
                                            visible: todoListCol.isToday && todoListCol.dayTodos.length > 0
                                            implicitWidth: addLbl.implicitWidth + Theme.spacingMd; implicitHeight: 22
                                            radius: Theme.radiusSm
                                            color: addMa.containsMouse ? Theme.withAlpha(Theme.secondary, 0.16) : "transparent"
                                            Text { id: addLbl; anchors.centerIn: parent; text: "+ add"; color: Theme.secondary; font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall }
                                            MouseArea { id: addMa; anchors.fill: parent; hoverEnabled: true; onClicked: TodoService.open = true }
                                        }
                                    }

                                    property var dayTodos: TodoService.dayTodos(calendarSection.selectedDate)
                                    readonly property bool isToday: calendarSection.selectedDate === TodoService.today

                                    Item {
                                        Layout.fillWidth: true
                                        visible: todoListCol.dayTodos.length === 0
                                        implicitHeight: 40
                                        Text {
                                            anchors.centerIn: parent
                                            text: todoListCol.isToday ? "No tasks yet
Tap + add to create one" : "No tasks for this day"
                                            color: Theme.surfaceTextDim
                                            font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }

                                    Repeater {
                                        model: {
                                            var l = todoListCol.dayTodos.slice()
                                            l.sort((a, b) => {
                                                if (a.pinned !== b.pinned) return a.pinned ? -1 : 1
                                                if (a.done !== b.done) return a.done ? 1 : -1
                                                return 0
                                            })
                                            return l
                                        }
                                        delegate: Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            implicitHeight: 36
                                            radius: Theme.radiusSm
                                            color: ma.containsMouse ? Theme.surfaceContainerHigh : "transparent"

                                            RowLayout {
                                                anchors { fill: parent; margins: Theme.spacingSm }
                                                spacing: Theme.spacingSm

                                                Rectangle {
                                                    width: 16; height: 16; radius: Theme.radiusXs
                                                    color: modelData.done ? Theme.secondary : "transparent"
                                                    border.color: modelData.done ? Theme.secondary : Theme.outline
                                                    border.width: 1
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "✓"
                                                        color: modelData.done ? Theme.surfaceContainerLowest : "transparent"
                                                        font.pointSize: Theme.labelLarge
                                                        font.bold: true
                                                    }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        enabled: todoListCol.isToday
                                                        onClicked: TodoService.setDone(calendarSection.selectedDate, modelData.id, !modelData.done)
                                                    }
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.text
                                                    color: modelData.done ? Theme.surfaceTextDim : (modelData.pinned ? Theme.secondary : Theme.surfaceText)
                                                    font.family: Theme.fontFamily
                                                    font.pointSize: Theme.bodySmall
                                                    font.strikeout: modelData.done
                                                    elide: Text.ElideRight
                                                }

                                                Rectangle {
                                                    visible: (modelData.time ?? "") !== ""
                                                    implicitWidth: calTimeLbl.implicitWidth + Theme.spacingSm
                                                    implicitHeight: 16
                                                    radius: Theme.radiusFull
                                                    color: Theme.withAlpha(Theme.primary, 0.14)
                                                    Text {
                                                        id: calTimeLbl
                                                        anchors.centerIn: parent
                                                        text: "󰥔 " + modelData.time + (modelData.remind > 0 ? " 󰂢" : "")
                                                        color: Theme.primary
                                                        font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall; font.bold: true
                                                    }
                                                }

                                                Rectangle {
                                                    width: 6; height: 6; radius: 3
                                                    color: modelData.pinned ? Theme.secondary : Theme.surfaceContainerHigh
                                                    opacity: ma.containsMouse || modelData.pinned ? 1.0 : 0.4
                                                    MouseArea {
                                                        anchors { fill: parent; margins: -4 }
                                                        enabled: todoListCol.isToday
                                                        onClicked: TodoService.togglePin(calendarSection.selectedDate, modelData.id)
                                                    }
                                                }
                                            }
                                            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; propagateComposedEvents: true }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── CONTROLS ──────────────────────────────────────
                    Item {
                        anchors.fill: parent
                        visible: root.tab === "controls"

                        // main controls
                        ColumnLayout {
                            anchors.fill: parent
                            visible: !root.showControlSettings
                            spacing: Theme.spacingLg

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingSm

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: root.muted ? "\u{f0581} " : (root.volume < 33 ? "\u{f057f} " : (root.volume < 66 ? "\u{f0580} " : "\u{f057e} "))
                                        color: Theme.secondary; font.family: Theme.fontFamily; font.pointSize: Theme.titleSmall
                                    }
                                    Text { text: "Volume"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; Layout.fillWidth: true }
                                    Text { text: root.muted ? "muted" : (root.volume + "%"); color: Theme.secondary; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge }
                                    Rectangle {
                                        implicitWidth: 24; implicitHeight: 20; radius: Theme.radiusSm
                                        color: root.muted ? Theme.withAlpha(Theme.secondary, 0.2) : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: root.muted ? "\u{f0581}" : "\u{f057e}"
                                            color: Theme.secondary; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                Quickshell.execDetached(["bash", "-c", "amixer sset Master toggle 1>/dev/null"])
                                                Qt.callLater(() => volPoll.running = true)
                                            }
                                        }
                                    }
                                }
                                SliderBar {
                                    Layout.fillWidth: true
                                    value: root.muted ? 0 : root.volume
                                    accentColor: Theme.secondary
                                    onMoved: v => {
                                        root.volume = v
                                        Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", (v / 100).toFixed(2)])
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingSm

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "󰃞"; color: Theme.warning; font.family: Theme.fontFamily; font.pointSize: Theme.titleSmall }
                                    Text { text: "Brightness"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; Layout.fillWidth: true }
                                    Text { text: root.brightness + "%"; color: Theme.warning; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge }
                                }
                                SliderBar {
                                    Layout.fillWidth: true
                                    value: root.brightness
                                    accentColor: Theme.warning
                                    onMoved: v => { root.brightness = v; Quickshell.execDetached(["brightnessctl", "set", v + "%"]) }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outlineVariant }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingMd

                                Repeater {
                                    model: [
                                        { icon: "\u{f05a9}", label: "WiFi",      cmd: ["nm-connection-editor"] },
                                        { icon: "󰂯", label: "Bluetooth", cmd: ["blueman-manager"] },
                                        { icon: "\u{f0594}", label: "Night",     cmd: ["bash", "-c", "gammastep -O 4500 &"] },
                                        { icon: "󰌾", label: "Lock",      cmd: ["hyprlock"] },
                                    ]
                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        implicitHeight: 56
                                        radius: Theme.radiusMd
                                        color: btnMa.containsMouse ? Theme.withAlpha(Theme.primary, 0.14) : Theme.surfaceContainerHigh

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: Theme.spacingXs
                                            Text { Layout.alignment: Qt.AlignHCenter; text: modelData.icon; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pointSize: Theme.titleMedium }
                                            Text { Layout.alignment: Qt.AlignHCenter; text: modelData.label; color: Theme.surfaceTextVariant; font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall }
                                        }
                                        MouseArea { id: btnMa; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(modelData.cmd) }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // nested settings sub-view
                        ColumnLayout {
                            id: settingsRoot
                            anchors.fill: parent
                            visible: root.showControlSettings
                            spacing: Theme.spacingMd

                            Text { text: "MODULE VISIBILITY"; color: Theme.surfaceTextVariant; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; font.bold: true }

                            Flickable {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                interactive: !SettingsService.editorDragging  // don't steal chip drags
                                contentHeight: settingsCol.implicitHeight

                                ColumnLayout {
                                    id: settingsCol
                                    width: parent.width
                                    spacing: Theme.spacingLg

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingSm

                                        // Drag-and-drop bar layout editor (click chips to toggle visibility)
                                        BarLayoutEditor { Layout.fillWidth: true }

                                        // Dashboard Position (not a bar module — kept as a separate toggle)
                                        Item {
                                            Layout.fillWidth: true
                                            implicitHeight: 28

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: Theme.spacingXs
                                                anchors.rightMargin: Theme.spacingXs
                                                spacing: Theme.spacingMd

                                                Text { text: "󰁎"; color: Theme.primary; font.family: Theme.fontFamily; font.pointSize: Theme.titleSmall; Layout.preferredWidth: 18 }
                                                Text {
                                                    text: "Dashboard Position — " + SettingsService.dashboardPosition
                                                    color: Theme.surfaceText
                                                    font.family: Theme.fontFamily
                                                    font.pointSize: Theme.labelLarge
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }
                                            }
                                            MouseArea { anchors.fill: parent; onClicked: root.toggleSetting("dashboardPosition") }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outlineVariant }

                                    Text { text: "AT A GLANCE CARDS"; color: Theme.surfaceTextVariant; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; font.bold: true }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingSm

                                        ToggleRow {
                                            icon: "󰻠"
                                            label: "CPU"
                                            checked: SettingsService.showGlanceCpu
                                            onToggled: v => SettingsService.showGlanceCpu = v
                                        }
                                        ToggleRow {
                                            icon: "󰍛"
                                            label: "Memory"
                                            checked: SettingsService.showGlanceMemory
                                            onToggled: v => SettingsService.showGlanceMemory = v
                                        }
                                        ToggleRow {
                                            icon: "󰋊"
                                            label: "Storage"
                                            checked: SettingsService.showGlanceStorage
                                            onToggled: v => SettingsService.showGlanceStorage = v
                                        }
                                        ToggleRow {
                                            icon: "󰔏"
                                            label: "Temperature"
                                            checked: SettingsService.showGlanceTemp
                                            onToggled: v => SettingsService.showGlanceTemp = v
                                        }
                                        ToggleRow {
                                            icon: "󰁹"
                                            label: "Battery"
                                            checked: SettingsService.showGlanceBattery
                                            visible: SettingsService.hasBattery
                                            onToggled: v => SettingsService.showGlanceBattery = v
                                        }
                                        ToggleRow {
                                            icon: "󰖩"
                                            label: "Network"
                                            checked: SettingsService.showGlanceNetwork
                                            onToggled: v => SettingsService.showGlanceNetwork = v
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outlineVariant }

                                    Text { text: "THEME"; color: Theme.surfaceTextVariant; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; font.bold: true }

                                    Text { text: "Active: " + Theme.prettyName(SettingsService.theme); color: Theme.surfaceTextVariant; font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall }

                                    ThemePicker { Layout.fillWidth: true }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outlineVariant }

                                    Text { text: "WALLPAPERS SOURCE"; color: Theme.surfaceTextVariant; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; font.bold: true }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingSm

                                        Text { text: "Directory to scan:"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 28
                                            radius: Theme.radiusSm
                                            color: Theme.surfaceContainerLow

                                            TextInput {
                                                anchors { fill: parent; leftMargin: Theme.spacingMd; rightMargin: Theme.spacingMd; verticalCenter: parent.verticalCenter }
                                                text: SettingsService.wallpaperDir
                                                color: Theme.surfaceText
                                                font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                                                selectByMouse: true
                                                verticalAlignment: TextInput.AlignVCenter
                                                onTextEdited: SettingsService.wallpaperDir = text
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 30
                                            radius: Theme.radiusSm
                                            color: scanMa.containsMouse ? Theme.withAlpha(Theme.primary, 0.2) : Theme.withAlpha(Theme.primary, 0.12)
                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰚔  Scan & Update list"
                                                color: Theme.primary; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; font.bold: true
                                            }
                                            MouseArea {
                                                id: scanMa
                                                anchors.fill: parent; hoverEnabled: true
                                                onClicked: { scanStatusText.text = "Scanning..."; scanStatusText.color = Theme.surfaceText; SettingsService.scanWallpapers() }
                                            }
                                        }

                                        Text {
                                            id: scanStatusText
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                            text: ""
                                            color: Theme.surfaceTextVariant; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                                        }

                                        Connections {
                                            target: SettingsService
                                            function onScanFinished(success, message) {
                                                scanStatusText.text = message
                                                scanStatusText.color = success ? Theme.success : Theme.error
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── SYSTEM STATS (at a glance) ───────────────────
                    Item {
                        anchors.fill: parent
                        visible: root.tab === "stats"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Theme.spacingMd

                            Text {
                                Layout.fillWidth: true
                                text: "󰻠  Live system usage"
                                color: Theme.surfaceTextVariant
                                font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall
                            }

                            Flickable {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                contentHeight: statsGrid.implicitHeight

                                Grid {
                                    id: statsGrid
                                    width: parent.width
                                    columns: 2
                                    spacing: Theme.spacingMd

                                    GlanceCard {
                                        width: (statsGrid.width - Theme.spacingMd) / 2
                                        visible: SettingsService.showGlanceCpu
                                        label: "CPU"
                                        icon: "󰻠"
                                        iconColor: Theme.error
                                        accent: Theme.error
                                        pollInterval: 3000
                                        command: ["bash", "-c", "grep '^cpu' /proc/stat > /tmp/qs-stat1; sleep 0.5; grep '^cpu' /proc/stat > /tmp/qs-stat2; paste /tmp/qs-stat1 /tmp/qs-stat2 | awk '$1 ~ /^cpu[0-9]+/ { t1=0; t2=0; for (i=2;i<=11;i++) t1+=$i; for (i=13;i<=22;i++) t2+=$i; d=t2-t1; if (d>0) printf \"%s %d\\n\", $1, int(100*(d-($16-$5))/d) }'"]
                                        transformFn: function(data) {
                                            var bars = [], total = 0, n = 0
                                            var lines = data.trim().split("\n")
                                            for (var i = 0; i < lines.length; i++) {
                                                var p = lines[i].trim().split(/\s+/)
                                                if (p.length !== 2) continue
                                                var c = parseInt(p[1])
                                                if (isNaN(c)) continue
                                                bars.push({ label: p[0].substring(3), pct: c })
                                                total += c; n++
                                            }
                                            if (n === 0) return null
                                            var avg = Math.round(total / n)
                                            return { value: avg + "%", pct: avg, sub: n + " cores", bars: bars }
                                        }
                                    }

                                    GlanceCard {
                                        width: (statsGrid.width - Theme.spacingMd) / 2
                                        visible: SettingsService.showGlanceMemory
                                        label: "Memory"
                                        icon: "󰍛"
                                        iconColor: Theme.warning
                                        accent: Theme.warning
                                        command: ["bash", "-c", "cat /proc/meminfo | grep -E '^(MemTotal|MemAvailable):'"]
                                        transformFn: function(data) {
                                            var total = 0, avail = 0
                                            var lines = data.split("\n")
                                            for (var i = 0; i < lines.length; i++) {
                                                var m = lines[i].match(/^(\w+):\s+(\d+)/)
                                                if (!m) continue
                                                if (m[1] === "MemTotal") total = parseInt(m[2]) / 1048576
                                                else if (m[1] === "MemAvailable") avail = parseInt(m[2]) / 1048576
                                            }
                                            if (!total) return null
                                            var used = total - avail
                                            var pct = Math.round((used / total) * 100)
                                            return { value: used.toFixed(1) + " GB", pct: pct, sub: "of " + total.toFixed(0) + " GB" }
                                        }
                                    }

                                    GlanceCard {
                                        id: storageGlance
                                        width: (statsGrid.width - Theme.spacingMd) / 2
                                        visible: SettingsService.showGlanceStorage
                                        label: "Storage ▾"
                                        icon: "󰋊"
                                        iconColor: Theme.surfaceTextVariant
                                        accent: Theme.surfaceTextVariant
                                        pollInterval: 30000
                                        command: ["bash", "-c", "df -h -P -l | awk 'NR>1 && ($6 == \"/\" || $6 ~ /^\\/mnt(\\/.*)?$/) {print $1\"|\"$2\"|\"$3\"|\"$4\"|\"$5\"|\"$6}'"]
                                        transformFn: function(data) {
                                            var lines = data.trim().split("\n").filter(function(l) { return l.trim() !== "" })
                                            root.storageLines = lines
                                            if (lines.length === 0) return { value: "—", pct: 0, sub: "No mounted drives" }
                                            var idx = root.storageIndex % lines.length
                                            var p = lines[idx].split("|")
                                            if (p.length < 6) return null
                                            var pct = parseInt(p[4]) || 0
                                            var multi = lines.length > 1
                                            return { value: pct + "%", pct: pct, sub: (multi ? "▸ " : "") + p[5] + " · " + p[3] + " free of " + p[2] }
                                        }
                                        onClicked: {
                                            if (root.storageLines.length > 1) {
                                                root.storageIndex = (root.storageIndex + 1) % root.storageLines.length
                                                storageGlance.repoll()
                                            }
                                        }
                                    }

                                    GlanceCard {
                                        width: (statsGrid.width - Theme.spacingMd) / 2
                                        visible: SettingsService.showGlanceTemp
                                        label: "Temperature"
                                        icon: "󰔏"
                                        iconColor: root.tempC >= 80 ? Theme.error : Theme.warning
                                        accent: root.tempC >= 80 ? Theme.error : Theme.warning
                                        pollInterval: 5000
                                        command: ["bash", "-c", "sensors 2>/dev/null | grep -oP 'temp1:\\s+\\+\\K[0-9]+' | head -1 || cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{printf \"%d\", $1/1000}'"]
                                        transformFn: function(data) {
                                            var v = parseInt(data.trim())
                                            if (isNaN(v)) return null
                                            root.tempC = v
                                            return { value: v + "°C", pct: Math.min(100, v), sub: v >= 80 ? "Critical — check cooling" : "CPU temp" }
                                        }
                                    }

                                    GlanceCard {
                                        width: (statsGrid.width - Theme.spacingMd) / 2
                                        visible: SettingsService.showGlanceBattery && SettingsService.hasBattery
                                        label: "Battery"
                                        icon: "󰁹"
                                        iconColor: root.batteryCap <= 20 ? Theme.error : root.batteryCap <= 30 ? Theme.warning : Theme.success
                                        accent: root.batteryCap <= 20 ? Theme.error : root.batteryCap <= 30 ? Theme.warning : Theme.success
                                        pollInterval: 5000
                                        command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1"]
                                        transformFn: function(data) {
                                            var lines = data.trim().split("\n")
                                            var cap = parseInt(lines[0])
                                            if (isNaN(cap)) return null
                                            root.batteryCap = cap
                                            var status = (lines[1] ?? "").trim()
                                            return { value: cap + "%", pct: cap, sub: status || "Battery" }
                                        }
                                    }

                                    GlanceCard {
                                        width: (statsGrid.width - Theme.spacingMd) / 2
                                        visible: SettingsService.showGlanceNetwork
                                        label: "Network"
                                        icon: "󰖩"
                                        iconColor: Theme.primary
                                        accent: Theme.primary
                                        pollInterval: 10000
                                        command: ["bash", "-c", `iface=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'dev \\K\\S+'); if [ -z "$iface" ]; then echo DISCONNECTED; exit 0; fi; ip=$(ip addr show "$iface" | grep -oP 'inet \\K[\\d.]+' | head -1); if [ -d /sys/class/net/$iface/wireless ]; then essid=$(iwgetid -r "$iface" 2>/dev/null); sig=$(awk 'NR==3{printf "%d", ($3/70)*100}' /proc/net/wireless 2>/dev/null); echo "WIFI|$essid|$sig|$ip"; else echo "ETH|$iface|$ip"; fi`]
                                        transformFn: function(data) {
                                            var s = data.trim()
                                            if (s === "DISCONNECTED" || s === "") return { value: "Offline", pct: 0, sub: "No network" }
                                            var parts = s.split("|")
                                            if (parts[0] === "WIFI") {
                                                var sig = parseInt(parts[2])
                                                return { value: parts[1], pct: isNaN(sig) ? 0 : sig, sub: "IP: " + (parts[3] ?? "") }
                                            }
                                            return { value: parts[1], pct: 100, sub: "IP: " + (parts[2] ?? "") }
                                        }
                                    }

                                    GlanceCard {
                                        width: (statsGrid.width - Theme.spacingMd) / 2
                                        visible: SettingsService.showGlanceCpu
                                        label: "Top Process"
                                        icon: "󰮡"
                                        iconColor: Theme.error
                                        accent: Theme.error
                                        pollInterval: 3000
                                        command: ["bash", "-c", "top -b -n1 | awk 'NR>=8 && NF>=12 {print $9\"|\"$1; exit}' | { IFS='|' read -r cpu pid; name=$(tr '\\0' ' ' < /proc/$pid/cmdline 2>/dev/null | cut -c1-40); echo \"$cpu|$name\"; }"]
                                        transformFn: function(data) {
                                            var s = data.trim()
                                            if (s === "") return null
                                            var p = s.split("|")
                                            var cpu = parseFloat(p[0])
                                            if (isNaN(cpu)) return null
                                            return { value: Math.round(cpu) + "%", pct: Math.min(100, Math.round(cpu)), sub: (p[1] ?? "").trim() + " · top CPU" }
                                        }
                                    }

                                    GlanceCard {
                                        width: (statsGrid.width - Theme.spacingMd) / 2
                                        visible: SettingsService.showGlanceNetwork
                                        label: "Traffic"
                                        icon: "󰲝"
                                        iconColor: Theme.primary
                                        accent: Theme.primary
                                        pollInterval: 5000
                                        command: ["bash", "-c", `iface=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'dev \\K\\S+'); [ -z "$iface" ] && { echo DISCONNECTED; exit 0; }; r1=$(awk -v i="$iface:" '$1==i{print $2}' /proc/net/dev); t1=$(awk -v i="$iface:" '$1==i{print $10}' /proc/net/dev); sleep 1; r2=$(awk -v i="$iface:" '$1==i{print $2}' /proc/net/dev); t2=$(awk -v i="$iface:" '$1==i{print $10}' /proc/net/dev); echo "$((r2-r1)) $((t2-t1)) $iface"`]
                                        transformFn: function(data) {
                                            var s = data.trim()
                                            if (s === "DISCONNECTED" || s === "") return { value: "Offline", pct: 0, sub: "No network" }
                                            var p = s.split(" ")
                                            if (p.length < 3) return null
                                            var rx = parseInt(p[0]) || 0, tx = parseInt(p[1]) || 0
                                            return { value: "↓ " + root.rate(rx) + "  ↑ " + root.rate(tx), pct: -1, sub: p[2] + " · Rx / Tx" }
                                        }
                                    }

                                    GlanceCard {
                                        width: (statsGrid.width - Theme.spacingMd) / 2
                                        visible: true
                                        label: "Uptime"
                                        icon: "󰅐"
                                        iconColor: Theme.success
                                        accent: Theme.success
                                        pollInterval: 30000
                                        command: ["bash", "-c", "cat /proc/loadavg /proc/uptime"]
                                        transformFn: function(data) {
                                            var lines = data.trim().split("\n")
                                            if (lines.length < 2) return null
                                            var l = lines[0].trim().split(/\s+/)
                                            var up = parseInt(lines[1])
                                            if (isNaN(up)) return null
                                            var d = Math.floor(up / 86400), h = Math.floor((up % 86400) / 3600), m = Math.floor((up % 3600) / 60)
                                            var upStr = d > 0 ? d + "d " + h + "h" : h > 0 ? h + "h " + m + "m" : m + "m"
                                            return { value: "Up " + upStr, pct: -1, sub: "Load " + l[0] + "  " + l[1] + "  " + l[2] }
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
