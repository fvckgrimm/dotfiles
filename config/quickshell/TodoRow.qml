import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// TodoRow — a single todo item in the list. Supports time + reminder
// scheduling: tap the clock (hover) or the time/reminder badge to open an
// inline scheduler.
Item {
    id: row

    property var    todo:       null
    property string dateStr:    ""
    property bool   isReadOnly: false

    implicitWidth:  200
    implicitHeight: content.implicitHeight + (row.editingTime ? editor.implicitHeight + Theme.spacingSm : 0) + Theme.spacingMd

    readonly property bool done:     todo?.done   ?? false
    readonly property bool pinned:   todo?.pinned ?? false
    readonly property bool hasTime:  (todo?.time ?? "") !== ""
    readonly property int  remind:   todo?.remind ?? 5
    property bool editing:    false
    property bool editingTime: false
    property string editText: todo?.text ?? ""
    property bool hovered: rowMa.containsMouse

    property int editHour:   9
    property int editMin:    0
    property int editRemind: 5

    function openTimeEditor() {
        if (row.todo.time) {
            var p = row.todo.time.split(":")
            row.editHour = parseInt(p[0]) || 0
            row.editMin  = parseInt(p[1]) || 0
        } else {
            var now = new Date()
            row.editHour = now.getHours()
            row.editMin  = now.getMinutes()
        }
        row.editRemind = row.todo.remind ?? 5
        row.editingTime = true
    }

    function applyTime() {
        var time = String(row.editHour).padStart(2, "0") + ":" + String(row.editMin).padStart(2, "0")
        TodoService.setSchedule(row.dateStr, row.todo.id, time, row.editRemind)
        row.editingTime = false
    }

    function clearTime() {
        TodoService.setSchedule(row.dateStr, row.todo.id, "", 5)
        row.editingTime = false
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMd
        color: {
            if (row.done)    return Theme.withAlpha(Theme.secondary, 0.06)
            if (row.pinned)  return Theme.withAlpha(Theme.secondary, 0.12)
            if (row.hovered) return Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity)
            return "transparent"
        }
        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    }

    RowLayout {
        id: content
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: Theme.spacingSm
        anchors.rightMargin: Theme.spacingSm
        spacing: Theme.spacingSm

        Rectangle {
            width: 16; height: 16; radius: Theme.radiusXs
            color:        row.done ? Theme.secondary : "transparent"
            border.color: row.done ? Theme.secondary : Theme.outline
            border.width: 1
            Behavior on color        { ColorAnimation { duration: Theme.motionMedium } }
            Behavior on border.color { ColorAnimation { duration: Theme.motionMedium } }

            Text {
                anchors.centerIn: parent
                text: "✓"
                color: row.done ? Theme.surfaceContainerLowest : "transparent"
                font.pointSize: Theme.labelLarge
                font.bold: true
            }
            MouseArea { anchors.fill: parent; onClicked: TodoService.setDone(row.dateStr, row.todo.id, !row.done) }
        }

        Rectangle {
            width: 6; height: 6; radius: 3
            color: row.pinned ? Theme.secondary : Theme.surfaceContainerHigh
            opacity: row.hovered || row.pinned ? 1.0 : 0.4
            Behavior on color { ColorAnimation { duration: Theme.motionFast } }
            MouseArea {
                anchors { fill: parent; margins: -4 }
                enabled: !row.isReadOnly
                onClicked: TodoService.togglePin(row.dateStr, row.todo.id)
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: row.editing ? editInput.implicitHeight + 4 : todoText.implicitHeight + 4

            Text {
                id: todoText
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                visible: !row.editing
                text: row.todo?.text ?? ""
                color: row.done ? Theme.surfaceTextDim : (row.pinned ? Theme.secondary : Theme.surfaceText)
                font.family: Theme.fontFamily
                font.pointSize: Theme.bodyMedium
                font.strikeout: row.done
                wrapMode: Text.WordWrap
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                MouseArea {
                    anchors.fill: parent
                    enabled: !row.isReadOnly
                    onDoubleClicked: {
                        row.editText = row.todo.text
                        row.editing  = true
                        Qt.callLater(() => editInput.forceActiveFocus())
                    }
                }
            }

            TextInput {
                id: editInput
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                visible: row.editing
                color: Theme.secondary
                font.family: Theme.fontFamily
                font.pointSize: Theme.bodyMedium
                selectionColor: Theme.withAlpha(Theme.secondary, 0.2)
                wrapMode: TextInput.WordWrap
                text: row.editText
                onTextChanged: row.editText = text

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        var t = row.editText.trim()
                        if (t !== "") TodoService.editTodo(row.dateStr, row.todo.id, t)
                        row.editing = false
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        row.editing = false
                        event.accepted = true
                    }
                }
            }
        }

        Row {
            spacing: Theme.spacingXs
            visible: row.hasTime

            Rectangle {
                implicitWidth: timeLbl.implicitWidth + Theme.spacingMd
                implicitHeight: 18
                radius: Theme.radiusFull
                color: row.done ? "transparent" : Theme.withAlpha(Theme.primary, 0.14)
                Text {
                    id: timeLbl
                    anchors.centerIn: parent
                    text: "󰥔 " + row.todo.time
                    color: row.done ? Theme.surfaceTextDim : Theme.primary
                    font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall; font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !row.isReadOnly
                    onClicked: row.openTimeEditor()
                }
            }

            Rectangle {
                visible: row.remind > 0
                implicitWidth: bellLbl.implicitWidth + Theme.spacingMd
                implicitHeight: 18
                radius: Theme.radiusFull
                color: row.done ? "transparent" : Theme.withAlpha(Theme.secondary, 0.14)
                Text {
                    id: bellLbl
                    anchors.centerIn: parent
                    text: "󰂢 " + row.remind + "m"
                    color: row.done ? Theme.surfaceTextDim : Theme.secondary
                    font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !row.isReadOnly
                    onClicked: row.openTimeEditor()
                }
            }
        }

        Row {
            spacing: Theme.spacingXs
            opacity: row.hovered && !row.isReadOnly ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }

            Text {
                visible: !row.hasTime
                text: "󰥔"
                color: clockMa.containsMouse ? Theme.primary : Theme.surfaceTextVariant
                font.pointSize: Theme.labelLarge
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    id: clockMa
                    anchors { fill: parent; margins: -4 }
                    hoverEnabled: true
                    onClicked: row.openTimeEditor()
                }
            }

            Text {
                text: "✕"
                color: Theme.error
                font.pointSize: Theme.labelLarge
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors { fill: parent; margins: -4 }
                    onClicked: TodoService.removeTodo(row.dateStr, row.todo.id)
                }
            }
        }
    }

    // Inline time/reminder editor (below the row)
    RowLayout {
        id: editor
        visible: row.editingTime
        anchors { left: parent.left; right: parent.right; top: content.bottom; topMargin: Theme.spacingSm }
        anchors.leftMargin: Theme.spacingSm
        anchors.rightMargin: Theme.spacingSm
        spacing: Theme.spacingXs

        Rectangle {
            implicitHeight: 24
            implicitWidth: timeEditorCol.implicitWidth
            radius: Theme.radiusSm
            color: Theme.surfaceContainerHigh

            RowLayout {
                id: timeEditorCol
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingSm
                anchors.rightMargin: Theme.spacingXs
                spacing: Theme.spacingXs

                Text { text: "󰥔"; color: Theme.primary; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge }
                TimeSpinner { width: 44; value: row.editHour; min: 0; max: 23; onValueChanged: row.editHour = value }
                Text { text: ":"; color: Theme.surfaceTextVariant; font.pointSize: Theme.titleMedium; font.bold: true }
                TimeSpinner { width: 44; value: row.editMin; min: 0; max: 59; step: 5; onValueChanged: row.editMin = value }
                Text { text: "󰂢"; color: Theme.secondary; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge }
                TimeSpinner { width: 44; value: row.editRemind; min: 0; max: 180; step: 5; onValueChanged: row.editRemind = value }
                Text { text: "min before"; color: Theme.surfaceTextDim; font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall }
            }
        }

        Item { Layout.fillWidth: true }

        Text {
            text: "✓"
            color: applyMa.containsMouse ? Theme.secondary : Theme.surfaceTextVariant
            font.pointSize: Theme.titleMedium; font.bold: true
            MouseArea { id: applyMa; anchors.fill: parent; hoverEnabled: true; onClicked: row.applyTime() }
        }
        Text {
            text: "✕"
            color: cancelMa.containsMouse ? Theme.surfaceText : Theme.surfaceTextDim
            font.pointSize: Theme.titleMedium
            MouseArea { id: cancelMa; anchors.fill: parent; hoverEnabled: true; onClicked: row.editingTime = false }
        }
        Text {
            text: "clear"
            color: clearMa.containsMouse ? Theme.error : Theme.surfaceTextDim
            font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall
            MouseArea { id: clearMa; anchors.fill: parent; hoverEnabled: true; onClicked: row.clearTime() }
        }
    }

    MouseArea {
        id: rowMa
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: mouse => mouse.accepted = false
    }
}
