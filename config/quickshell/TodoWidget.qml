import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// TodoWidget — full-screen overlay panel, same pattern as LauncherPopup.
PanelWindow {
    id: root

    required property var barWindow
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell:todo"
    exclusiveZone: 0
    anchors {}

    implicitWidth:  screen.width
    implicitHeight: screen.height
    color: "transparent"
    screen: barWindow ? barWindow.screen : undefined

    property string viewDate: TodoService.today
    property string inputText: ""
    property string inputTime: ""
    property int    inputRemind: 5
    property bool   inputTimeOpen: false
    property int    inputHour: 9
    property int    inputMin: 0

    readonly property bool isToday: viewDate === TodoService.today
    readonly property var  dayList: TodoService.dayTodos(viewDate)

    readonly property var sortedList: {
        var l = dayList.slice()
        l.sort((a, b) => {
            if (a.pinned !== b.pinned) return a.pinned ? -1 : 1
            if (a.done   !== b.done)   return a.done   ?  1 : -1
            // Sort by time if both have time
            if (a.time && b.time) return a.time.localeCompare(b.time)
            if (a.time) return -1
            if (b.time) return 1
            return 0
        })
        return l
    }

    readonly property int doneCount:    dayList.filter(t => t.done).length
    readonly property int pendingCount: dayList.filter(t => !t.done).length

    function open() {
        viewDate   = TodoService.today
        inputText  = ""
        inputTime  = ""
        inputRemind = 5
        inputTimeOpen = false
        visible    = true
        Qt.callLater(() => todoInput.forceActiveFocus())
    }

    function toggleInputTime() {
        root.inputTimeOpen = !root.inputTimeOpen
        if (root.inputTimeOpen) {
            if (root.inputTime !== "") {
                var p = root.inputTime.split(":")
                root.inputHour = parseInt(p[0]) || 0
                root.inputMin  = parseInt(p[1]) || 0
            } else {
                var now = new Date()
                root.inputHour = now.getHours()
                root.inputMin  = now.getMinutes()
            }
        }
    }

    function close() { visible = false; TodoService.open = false }

    function prevDay() {
        var d = new Date(viewDate + "T12:00:00")
        d.setDate(d.getDate() - 1)
        viewDate = Qt.formatDate(d, "yyyy-MM-dd")
    }

    function nextDay() {
        var d = new Date(viewDate + "T12:00:00")
        d.setDate(d.getDate() + 1)
        var next = Qt.formatDate(d, "yyyy-MM-dd")
        if (next <= TodoService.today) viewDate = next
    }

    function friendlyDate(ds) {
        if (ds === TodoService.today) return "Today"
        var t = new Date(TodoService.today + "T12:00:00")
        t.setDate(t.getDate() - 1)
        if (ds === Qt.formatDate(t, "yyyy-MM-dd")) return "Yesterday"
        var d = new Date(ds + "T12:00:00")
        return d.toLocaleDateString(Qt.locale(), "ddd, MMM d")
    }

    property bool _ready: false
    Component.onCompleted: Qt.callLater(() => { _ready = true })

    Connections {
        target: TodoService
        function onOpenChanged() {
            if (!root._ready) return
            if (TodoService.open) root.open()
            else if (root.visible) root.close()
        }
    }

    onVisibleChanged: { if (_ready && !visible) TodoService.open = false }

    Rectangle {
        anchors.fill: parent
        color: Theme.withAlpha("#000000", 0.55)

        MouseArea { anchors.fill: parent; onClicked: root.close() }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width:  440
            height: Math.min(cardCol.implicitHeight + Theme.spacingXl * 2, 650)
            radius: Theme.radiusXl
            color:  Theme.cardColor()
            border.color: Theme.cardBorder()
            border.width: 1

            MouseArea { anchors.fill: parent; onClicked: {} }

            ColumnLayout {
                id: cardCol
                anchors { fill: parent; margins: Theme.spacingXl }
                spacing: Theme.spacingMd

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSm

                    Rectangle {
                        width: 24; height: 24; radius: Theme.radiusSm
                        color: prevMa.containsMouse ? Theme.withAlpha(Theme.secondary, 0.16) : "transparent"
                        Text { anchors.centerIn: parent; text: "‹"; color: Theme.secondary; font.pointSize: Theme.titleMedium; font.bold: true }
                        MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.prevDay() }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.friendlyDate(root.viewDate)
                            color: root.isToday ? Theme.secondary : Theme.surfaceTextVariant
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.bodyLarge
                            font.bold: true
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.viewDate
                            color: Theme.surfaceTextDim
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.labelSmall
                            visible: !root.isToday
                        }
                    }

                    Rectangle {
                        width: 24; height: 24; radius: Theme.radiusSm
                        opacity: root.isToday ? 0.25 : 1.0
                        color: nextMa.containsMouse && !root.isToday ? Theme.withAlpha(Theme.secondary, 0.16) : "transparent"
                        Text { anchors.centerIn: parent; text: "›"; color: Theme.secondary; font.pointSize: Theme.titleMedium; font.bold: true }
                        MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; onClicked: if (!root.isToday) root.nextDay() }
                    }

                    Rectangle {
                        visible: !root.isToday
                        implicitWidth: todayLbl.implicitWidth + Theme.spacingMd; implicitHeight: 24
                        radius: Theme.radiusSm
                        color: todayMa.containsMouse ? Theme.withAlpha(Theme.secondary, 0.16) : "transparent"
                        Text { id: todayLbl; anchors.centerIn: parent; text: "↩ today"; color: Theme.secondary; font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall }
                        MouseArea { id: todayMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.viewDate = TodoService.today }
                    }

                    Rectangle {
                        visible: root.doneCount > 0
                        implicitWidth: clearLbl.implicitWidth + Theme.spacingMd; implicitHeight: 24
                        radius: Theme.radiusSm
                        color: clearMa.containsMouse ? Theme.withAlpha(Theme.error, 0.16) : "transparent"
                        Text { id: clearLbl; anchors.centerIn: parent; text: "clear done"; color: Theme.error; font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall }
                        MouseArea { id: clearMa; anchors.fill: parent; hoverEnabled: true; onClicked: TodoService.clearDone(root.viewDate) }
                    }

                    Text {
                        text: "✕"; color: Theme.surfaceTextVariant; font.pointSize: Theme.titleSmall
                        MouseArea { anchors.fill: parent; onClicked: root.close() }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 16
                    visible: root.dayList.length > 0

                    Rectangle {
                        anchors { left: parent.left; right: countLbl.left; rightMargin: Theme.spacingSm; verticalCenter: parent.verticalCenter }
                        height: 4; radius: Theme.radiusFull
                        color: Theme.surfaceContainerHigh
                        Rectangle {
                            width: root.dayList.length > 0 ? parent.width * (root.doneCount / root.dayList.length) : 0
                            height: parent.height; radius: Theme.radiusFull
                            color: Theme.secondary
                            Behavior on width { NumberAnimation { duration: Theme.motionSlow; easing.type: Theme.easingStandard } }
                        }
                    }

                    Text {
                        id: countLbl
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text: root.doneCount + "/" + root.dayList.length
                        color: Theme.surfaceTextDim; font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outlineVariant }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Theme.radiusMd
                    visible: root.isToday
                    color: Theme.surfaceContainerLow

                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.spacingMd; rightMargin: Theme.spacingSm }
                        spacing: Theme.spacingSm

                        Text { text: "+"; color: Theme.secondary; font.pointSize: Theme.titleMedium; font.bold: true }

                        Rectangle {
                            width: 24; height: 24; radius: Theme.radiusSm
                            color: (inputTimeMa.containsMouse || root.inputTimeOpen) ? Theme.withAlpha(Theme.secondary, 0.16) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "󰥔"
                                color: root.inputTime !== "" ? Theme.secondary : Theme.surfaceTextVariant
                                font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                            }
                            MouseArea {
                                id: inputTimeMa
                                anchors.fill: parent; hoverEnabled: true
                                onClicked: root.toggleInputTime()
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: todoInput.implicitHeight

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "add a task…"
                                color: Theme.surfaceTextDim
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.bodyMedium
                                visible: todoInput.text === ""
                            }

                            TextInput {
                                id: todoInput
                                anchors.fill: parent
                                color: Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pointSize: Theme.bodyMedium
                                selectionColor: Theme.withAlpha(Theme.secondary, 0.2)
                                focus: true
                                text: root.inputText
                                onTextChanged: root.inputText = text

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        var t = root.inputText.trim()
                                        if (t !== "") {
                                            TodoService.addTodo(t, undefined, root.inputTime, root.inputRemind)
                                            root.inputText = ""
                                            root.inputTime = ""
                                            root.inputRemind = 5
                                            text = ""
                                        }
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Escape) {
                                        root.close()
                                        event.accepted = true
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: root.inputTime !== ""
                            implicitWidth: inputTimeBadge.implicitWidth + Theme.spacingMd
                            implicitHeight: 20
                            radius: Theme.radiusFull
                            color: Theme.withAlpha(Theme.secondary, 0.16)
                            Text {
                                id: inputTimeBadge
                                anchors.centerIn: parent
                                text: "󰥔 " + root.inputTime + (root.inputRemind > 0 ? "  󰂢 " + root.inputRemind + "m" : "")
                                color: Theme.secondary
                                font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall; font.bold: true
                            }
                        }

                        Text { visible: root.inputText.trim() !== ""; text: "↵"; color: Theme.secondary; font.pointSize: Theme.bodyMedium; opacity: 0.7 }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacingXs
                    visible: root.inputTimeOpen
                    spacing: Theme.spacingXs

                    Rectangle {
                        implicitHeight: 24
                        implicitWidth: inputEditorCol.implicitWidth
                        radius: Theme.radiusSm
                        color: Theme.surfaceContainerHigh

                        RowLayout {
                            id: inputEditorCol
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingSm
                            anchors.rightMargin: Theme.spacingXs
                            spacing: Theme.spacingXs

                            Text { text: "󰥔"; color: Theme.primary; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge }
                            TimeSpinner { width: 44; value: root.inputHour; min: 0; max: 23; onValueChanged: root.inputHour = value }
                            Text { text: ":"; color: Theme.surfaceTextVariant; font.pointSize: Theme.titleMedium; font.bold: true }
                            TimeSpinner { width: 44; value: root.inputMin; min: 0; max: 59; step: 5; onValueChanged: root.inputMin = value }
                            Text { text: "󰂢"; color: Theme.secondary; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge }
                            TimeSpinner { width: 44; value: root.inputRemind; min: 0; max: 180; step: 5; onValueChanged: root.inputRemind = value }
                            Text { text: "min before"; color: Theme.surfaceTextDim; font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "✓"
                        color: inputApplyMa.containsMouse ? Theme.secondary : Theme.surfaceTextVariant
                        font.pointSize: Theme.titleMedium; font.bold: true
                        MouseArea {
                            id: inputApplyMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                root.inputTime = String(root.inputHour).padStart(2, "0") + ":" + String(root.inputMin).padStart(2, "0")
                                root.inputTimeOpen = false
                                Qt.callLater(() => todoInput.forceActiveFocus())
                            }
                        }
                    }
                    Text {
                        text: "✕"
                        color: inputCancelMa.containsMouse ? Theme.surfaceText : Theme.surfaceTextDim
                        font.pointSize: Theme.titleMedium
                        MouseArea {
                            id: inputCancelMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: root.inputTimeOpen = false
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 52
                    visible: root.dayList.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Theme.spacingXs
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.isToday ? "󰄲  nothing yet" : "󰄲  no tasks"
                            color: Theme.surfaceTextDim; font.family: Theme.fontFamily; font.pointSize: Theme.bodyMedium
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.isToday ? "type above and hit enter" : ""
                            color: Theme.surfaceTextDim; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                            visible: root.isToday
                        }
                    }
                }

                Flickable {
                    id: flick
                    Layout.fillWidth: true
                    implicitHeight: Math.min(todoCol.implicitHeight, 380)
                    contentHeight: todoCol.implicitHeight
                    clip: true
                    visible: root.dayList.length > 0

                    ColumnLayout {
                        id: todoCol
                        width: flick.width
                        spacing: Theme.spacingXs

                        Repeater {
                            model: root.sortedList
                            delegate: TodoRow {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                todo: modelData
                                dateStr: root.viewDate
                                isReadOnly: !root.isToday
                            }
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.isToday
                        ? (root.pendingCount > 0 ? root.pendingCount + " remaining  ·  esc close" : "all done  ✓  ·  esc close")
                        : (root.dayList.length + " task" + (root.dayList.length !== 1 ? "s" : "") + "  ·  esc close")
                    color: (root.isToday && root.pendingCount === 0 && root.dayList.length > 0) ? Theme.secondary : Theme.surfaceTextDim
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.labelSmall
                }
            }
        }
    }
}
