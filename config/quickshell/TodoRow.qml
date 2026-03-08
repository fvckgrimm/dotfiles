import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// TodoRow — a single todo item in the list.
// Supports: check/uncheck, pin, inline edit, delete.
Item {
    id: row

    property var    todo:       null
    property string dateStr:    ""
    property bool   isReadOnly: false

    implicitWidth:  200
    implicitHeight: content.implicitHeight + 10

    readonly property bool done:   todo?.done   ?? false
    readonly property bool pinned: todo?.pinned ?? false

    property bool editing:    false
    property string editText: todo?.text ?? ""

    // Hover tracking
    property bool hovered: rowMa.containsMouse

    // ── Background ────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 5
        color: {
            if (row.done)    return "#08e8b86a"
            if (row.pinned)  return "#12e8b86a"
            if (row.hovered) return "#10e8b86a"
            return "transparent"
        }
        border.color: {
            if (row.pinned)  return "#30e8b86a"
            if (row.hovered) return "#18e8b86a"
            return "transparent"
        }
        border.width: 1
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    RowLayout {
        id: content
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 6

        // ── Checkbox ──────────────────────────────────────────────────────────
        Rectangle {
            width: 16; height: 16; radius: 3
            color:        row.done ? "#e8b86a" : "transparent"
            border.color: row.done ? "#e8b86a" : "#445e7a"
            border.width: 1
            Behavior on color       { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "✓"
                color: row.done ? "#0d1117" : "transparent"
                font.pointSize: 7
                font.bold: true
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: TodoService.setDone(row.dateStr, row.todo.id, !row.done)
            }
        }

        // ── Pin dot ───────────────────────────────────────────────────────────
        Rectangle {
            width: 6; height: 6; radius: 3
            color: row.pinned ? "#e8b86a" : "#1e2535"
            border.color: row.pinned ? "#e8b86a" : "#2a3448"
            border.width: 1
            opacity: row.hovered || row.pinned ? 1.0 : 0.4
            Behavior on color { ColorAnimation { duration: 120 } }
            MouseArea {
                anchors { fill: parent; margins: -4 }
                enabled: !row.isReadOnly
                onClicked: TodoService.togglePin(row.dateStr, row.todo.id)
            }
        }

        // ── Text / Edit ───────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            implicitHeight: row.editing ? editInput.implicitHeight + 4 : todoText.implicitHeight + 4

            // Display mode
            Text {
                id: todoText
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                visible: !row.editing
                text: row.todo?.text ?? ""
                color: row.done ? "#444d62" : (row.pinned ? "#d4a84b" : "#c8d2e0")
                font.family:          Theme.fontFamily
                font.pointSize:       8
                font.strikeout:       row.done
                wrapMode:             Text.WordWrap
                Behavior on color { ColorAnimation { duration: 120 } }

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

            // Edit mode
            TextInput {
                id: editInput
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                visible: row.editing
                color: "#e8b86a"
                font.family:    Theme.fontFamily
                font.pointSize: 8
                selectionColor: "#33e8b86a"
                wrapMode:       TextInput.WordWrap
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

        // ── Actions (visible on hover) ────────────────────────────────────────
        Row {
            spacing: 3
            opacity: row.hovered && !row.isReadOnly ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 120 } }

            // Delete button
            Text {
                text: "✕"
                color: "#ff416c"
                font.pointSize: 7
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors { fill: parent; margins: -4 }
                    onClicked: TodoService.removeTodo(row.dateStr, row.todo.id)
                }
            }
        }
    }

    // Row-level hover area (behind everything)
    MouseArea {
        id: rowMa
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: mouse => mouse.accepted = false
    }
}
