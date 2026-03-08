import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// TodoWidget — full-screen overlay panel, same pattern as LauncherPopup.
// Instantiated in Bar.qml (one per screen). Keyboard focus works properly.
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

    // ── State ─────────────────────────────────────────────────────────────────
    property string viewDate: TodoService.today
    property string inputText: ""

    readonly property bool isToday: viewDate === TodoService.today
    readonly property var  dayList: TodoService.dayTodos(viewDate)

    readonly property var sortedList: {
        var l = dayList.slice()
        l.sort((a, b) => {
            if (a.pinned !== b.pinned) return a.pinned ? -1 : 1
            if (a.done   !== b.done)   return a.done   ?  1 : -1
            return 0
        })
        return l
    }

    readonly property int doneCount:    dayList.filter(t => t.done).length
    readonly property int pendingCount: dayList.filter(t => !t.done).length

    function open() {
        viewDate  = TodoService.today
        inputText = ""
        visible   = true
        Qt.callLater(() => todoInput.forceActiveFocus())
    }

    function close() {
        visible = false
        TodoService.open = false
    }

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

    onVisibleChanged: {
        if (_ready && !visible) TodoService.open = false
    }

    // ── Full-screen dim backdrop ──────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#aa000000"

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        // ── Centered card ─────────────────────────────────────────────────────
        Rectangle {
            id: card
            anchors.centerIn: parent
            width:  400
            height: Math.min(cardCol.implicitHeight + 28, 620)
            radius: 10
            color:  "#f2110e18"
            border.color: "#40c8a063"
            border.width: 1

            // Warm top glow line
            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 1; radius: 1
                color: "#55e8b86a"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                id: cardCol
                anchors { fill: parent; margins: 16 }
                spacing: 10

                // ── Header ────────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        width: 22; height: 22; radius: 3
                        color: prevMa.containsMouse ? "#22e8b86a" : "transparent"
                        border.color: "#33e8b86a"; border.width: 1
                        Text { anchors.centerIn: parent; text: "‹"; color: "#e8b86a"; font.pointSize: 11; font.bold: true }
                        MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.prevDay() }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.friendlyDate(root.viewDate)
                            color: root.isToday ? "#e8b86a" : "#9aa5c4"
                            font.family: Theme.fontFamily
                            font.pointSize: 10
                            font.bold: true
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.viewDate
                            color: "#444d62"
                            font.family: Theme.fontFamily
                            font.pointSize: 6
                            visible: !root.isToday
                        }
                    }

                    Rectangle {
                        width: 22; height: 22; radius: 3
                        opacity: root.isToday ? 0.2 : 1.0
                        color: nextMa.containsMouse && !root.isToday ? "#22e8b86a" : "transparent"
                        border.color: "#33e8b86a"; border.width: 1
                        Text { anchors.centerIn: parent; text: "›"; color: "#e8b86a"; font.pointSize: 11; font.bold: true }
                        MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; onClicked: if (!root.isToday) root.nextDay() }
                    }

                    Rectangle {
                        visible: !root.isToday
                        implicitWidth: todayLbl.implicitWidth + 12; implicitHeight: 22
                        radius: 3
                        color: todayMa.containsMouse ? "#22e8b86a" : "transparent"
                        border.color: "#33e8b86a"; border.width: 1
                        Text { id: todayLbl; anchors.centerIn: parent; text: "↩ today"; color: "#e8b86a"; font.family: Theme.fontFamily; font.pointSize: 6 }
                        MouseArea { id: todayMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.viewDate = TodoService.today }
                    }

                    Rectangle {
                        visible: root.doneCount > 0
                        implicitWidth: clearLbl.implicitWidth + 12; implicitHeight: 22
                        radius: 3
                        color: clearMa.containsMouse ? "#22ff416c" : "transparent"
                        border.color: "#33ff416c"; border.width: 1
                        Text { id: clearLbl; anchors.centerIn: parent; text: "clear done"; color: "#ff416c"; font.family: Theme.fontFamily; font.pointSize: 6 }
                        MouseArea { id: clearMa; anchors.fill: parent; hoverEnabled: true; onClicked: TodoService.clearDone(root.viewDate) }
                    }

                    Text {
                        text: "✕"; color: "#7984a4"; font.pointSize: 10
                        MouseArea { anchors.fill: parent; onClicked: root.close() }
                    }
                }

                // ── Progress bar ──────────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 16
                    visible: root.dayList.length > 0

                    Rectangle {
                        anchors { left: parent.left; right: countLbl.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        height: 4; radius: 2
                        color: "#1ae8b86a"

                        Rectangle {
                            width: root.dayList.length > 0
                                ? parent.width * (root.doneCount / root.dayList.length) : 0
                            height: parent.height; radius: 2
                            color: "#e8b86a"
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }
                    }

                    Text {
                        id: countLbl
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text: root.doneCount + "/" + root.dayList.length
                        color: "#555e7a"; font.family: Theme.fontFamily; font.pointSize: 6
                    }
                }

                // ── Divider ───────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true; height: 1
                    color: "#1ae8b86a"
                }

                // ── Input (today only) ────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: 5
                    visible: root.isToday
                    color: todoInput.activeFocus ? "#1ae8b86a" : "#0ae8b86a"
                    border.color: todoInput.activeFocus ? "#55e8b86a" : "#22e8b86a"
                    border.width: 1

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 10 }
                        spacing: 8

                        Text { text: "+"; color: "#e8b86a"; font.pointSize: 12; font.bold: true }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: todoInput.implicitHeight

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "add a task…"
                                color: "#444d62"
                                font.family: Theme.fontFamily
                                font.pointSize: 9
                                visible: todoInput.text === ""
                            }

                            TextInput {
                                id: todoInput
                                anchors.fill: parent
                                color: "#d8e0f0"
                                font.family: Theme.fontFamily
                                font.pointSize: 9
                                selectionColor: "#33e8b86a"
                                focus: true
                                text: root.inputText
                                onTextChanged: root.inputText = text

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        var t = root.inputText.trim()
                                        if (t !== "") {
                                            TodoService.addTodo(t)
                                            root.inputText = ""
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

                        Text {
                            visible: root.inputText.trim() !== ""
                            text: "↵"; color: "#e8b86a"; font.pointSize: 9; opacity: 0.7
                        }
                    }
                }

                // ── Empty state ───────────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 52
                    visible: root.dayList.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.isToday ? "󰄲  nothing yet" : "󰄲  no tasks"
                            color: "#444d62"; font.family: Theme.fontFamily; font.pointSize: 9
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.isToday ? "type above and hit enter" : ""
                            color: "#333a4d"; font.family: Theme.fontFamily; font.pointSize: 7
                            visible: root.isToday
                        }
                    }
                }

                // ── Todo list ─────────────────────────────────────────────────
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
                        spacing: 4

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

                // ── Footer hint ───────────────────────────────────────────────
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.isToday
                        ? (root.pendingCount > 0
                            ? root.pendingCount + " remaining  ·  esc close"
                            : "all done  ✓  ·  esc close")
                        : (root.dayList.length + " task" + (root.dayList.length !== 1 ? "s" : "") + "  ·  esc close")
                    color: (root.isToday && root.pendingCount === 0 && root.dayList.length > 0)
                        ? "#e8b86a" : "#444d62"
                    font.family: Theme.fontFamily
                    font.pointSize: 6
                }
            }
        }
    }
}
