import QtQuick
import QtQuick.Layouts

// Reusable settings row: icon + label + sliding switch toggle.
// Used in the Dashboard settings sub-view (e.g. at-a-glance card visibility).
RowLayout {
    id: root
    property string icon: ""
    property string label: ""
    property bool checked: false

    signal toggled(bool value)

    Layout.fillWidth: true
    implicitHeight: 28
    spacing: Theme.spacingMd

    Text {
        text: root.icon
        color: root.checked ? Theme.primary : Theme.surfaceTextVariant
        font.family: Theme.fontFamily
        font.pointSize: Theme.titleSmall
        Layout.preferredWidth: 18
        Layout.alignment: Qt.AlignVCenter
    }
    Text {
        text: root.label
        color: Theme.surfaceText
        font.family: Theme.fontFamily
        font.pointSize: Theme.labelLarge
        Layout.fillWidth: true
        elide: Text.ElideRight
    }
    Rectangle {
        width: 40; height: 22; radius: Theme.radiusFull
        color: root.checked ? Theme.withAlpha(Theme.primary, 0.3) : Theme.surfaceContainerHigh
        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
        Rectangle {
            x: root.checked ? 20 : 2
            anchors.verticalCenter: parent.verticalCenter
            width: 18; height: 18; radius: Theme.radiusFull
            color: root.checked ? Theme.primary : Theme.surfaceTextDim
            Behavior on x { NumberAnimation { duration: Theme.motionMedium; easing.type: Theme.easingStandard } }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.toggled(!root.checked)
        }
    }
}
