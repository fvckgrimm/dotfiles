import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Generic info chip: icon + value text. Flat by default — a subtle hover
// tint is the only surface change, so the bar doesn't read as a strip of
// separately-boxed modules.
Rectangle {
    id: root
    property string icon: ""
    property string value: "—"
    property string iconColor: Theme.surfaceText
    property string valueColor: Theme.surfaceText
    // Deprecated — kept so existing call sites don't break, no longer rendered.
    property string accentColor: "transparent"
    property string tooltipText: ""
    property string bgColor: "transparent"

    signal clicked()
    signal rightClicked()
    signal wheel(var wheel)

    property bool hovered: ma.containsMouse

    implicitHeight: 26
    implicitWidth: row.implicitWidth + Theme.spacingLg * 2
    radius: Theme.radiusMd
    color: hovered ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : bgColor
    border.width: 0
    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacingSm

        Text {
            text: root.icon
            color: root.iconColor
            font.family: Theme.fontFamily
            font.pointSize: Theme.titleSmall
            font.bold: true
        }
        Text {
            text: root.value
            color: root.valueColor
            font.family: Theme.fontFamily
            font.pointSize: Theme.bodyMedium
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
        onWheel: wheel => root.wheel(wheel)
    }

    ToolTip {
        visible: ma.containsMouse && root.tooltipText !== ""
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
