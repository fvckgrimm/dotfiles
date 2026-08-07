import Quickshell
import QtQuick

// Small flat icon button used by media UI (bar + control center).
// Material-style tonal hover, no borders.
Rectangle {
    id: root
    property string glyph: ""
    property string tooltipText: ""
    property int size: 20
    property string colorInactive: Theme.surfaceTextVariant
    signal clicked()

    implicitWidth: root.size
    implicitHeight: root.size
    radius: Theme.radiusSm
    color: ma.containsMouse ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        color: ma.containsMouse ? Theme.surfaceText : root.colorInactive
        font.family: Theme.fontFamily
        font.pointSize: root.size > 24 ? Theme.titleSmall : Theme.labelLarge
        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
