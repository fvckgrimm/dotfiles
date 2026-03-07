import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Generic info chip: icon + value text, with optional left accent border
Rectangle {
    id: root

    property string icon: ""
    property string value: "—"
    property string iconColor: "#e5e5e5"
    property string valueColor: "#e5e5e5"
    property string accentColor: "transparent"
    property string tooltipText: ""
    property string bgColor: "#661e1e28"

    signal clicked()
    signal rightClicked()

    implicitHeight: 22
    implicitWidth: row.implicitWidth + 20
    radius: 2
    color: hovered ? "#991e1e28" : bgColor
    border.color: "transparent"

    property bool hovered: ma.containsMouse

    Behavior on color { ColorAnimation { duration: 150 } }

    // left accent line
    Rectangle {
        visible: root.accentColor !== "transparent"
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 1
        color: root.accentColor
        radius: 1
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: root.icon
            color: root.iconColor
            font.family: "JetBrainsMono Nerd Font"
            font.pointSize: 9
            font.bold: true
        }
        Text {
            text: root.value
            color: root.valueColor
            font.family: "JetBrainsMono Nerd Font"
            font.pointSize: 8
            font.bold: true
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.rightClicked()
            else root.clicked()
        }
    }

    ToolTip {
        visible: ma.containsMouse && root.tooltipText !== ""
        text: root.tooltipText
        delay: 600
        background: Rectangle {
            color: "#d90d1117"
            border.color: "#335bcefa"
            radius: 4
        }
        contentItem: Text {
            text: root.tooltipText
            color: "#d8e0f0"
            font.family: "JetBrainsMono Nerd Font"
            font.pointSize: 8
        }
    }
}
