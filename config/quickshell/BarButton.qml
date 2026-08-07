import QtQuick
import QtQuick.Controls

// Reusable flat bar button. No permanent borders/backgrounds — state is
// communicated with a Material-style hover/active tonal layer instead of
// a colored border, so the bar reads as one surface, not a row of boxes.
Rectangle {
    id: root
    property string text: ""
    property string textColor: Theme.surfaceText
    // Accent color for the "active/toggled" state. "transparent" = inactive.
    property string borderColor: "transparent"
    property string tooltipText: ""
    property string bgColor: "transparent"

    signal clicked()
    signal rightClicked()
    signal wheel(var wheel)

    readonly property bool isActive: borderColor !== "transparent"
    property bool hovered: mouseArea.containsMouse

    implicitWidth: label.implicitWidth + Theme.spacingLg * 2
    implicitHeight: 26
    radius: Theme.radiusMd
    color: isActive
        ? Theme.withAlpha(borderColor, hovered ? 0.22 : 0.14)
        : (hovered ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : bgColor)
    border.width: 0

    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.isActive ? root.borderColor : root.textColor
        font.family: Theme.fontFamily
        font.pointSize: Theme.titleSmall
        font.bold: true
        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
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

    ToolTip {
        visible: mouseArea.containsMouse && root.tooltipText !== ""
        text: root.tooltipText
        delay: 600
        background: Rectangle {
            color: Theme.cardColor()
            border.color: Theme.cardBorder()
            border.width: 1
            radius: Theme.radiusSm
        }
        contentItem: Text {
            text: root.tooltipText
            color: Theme.surfaceText
            font.family: Theme.fontFamily
            font.pointSize: Theme.labelLarge
        }
    }
}
