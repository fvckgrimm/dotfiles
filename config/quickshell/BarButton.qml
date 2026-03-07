import QtQuick
import QtQuick.Controls

// Reusable pill-style button used for launcher, screenshot, power, etc.
Rectangle {
    id: root

    property string text: ""
    property string textColor: "#e5e5e5"
    property string borderColor: "transparent"
    property string tooltipText: ""
    property string bgColor: "#661e1e28"

    signal clicked()
    signal rightClicked()

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 22
    radius: 2
    color: hovered ? "#991e1e28" : bgColor
    border.color: borderColor
    border.width: 1

    property bool hovered: mouseArea.containsMouse

    Behavior on color { ColorAnimation { duration: 150 } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.textColor
        font.family: "JetBrainsMono Nerd Font"
        font.pointSize: 10
        font.bold: true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.rightClicked()
            else root.clicked()
        }
        onWheel: wheel => root.wheel(wheel)
    }

    signal wheel(var wheel)

    // Tooltip
    ToolTip {
        visible: mouseArea.containsMouse && root.tooltipText !== ""
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
