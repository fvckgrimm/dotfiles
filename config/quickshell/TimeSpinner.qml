import QtQuick
import QtQuick.Layouts

// Simple +/- spinner for hour or minute values.
Item {
    id: spinner
    property int value: 0
    property int min:   0
    property int max:   23
    property int step:  1
    implicitWidth:  72
    implicitHeight: 24

    function increment() { var v = value + step; value = v > max ? min : v }
    function decrement() { var v = value - step; value = v < min ? max : v }

    RowLayout {
        anchors.fill: parent
        spacing: Theme.spacingXs

        Rectangle {
            width: 20; height: 24; radius: Theme.radiusSm
            color: decMa.containsMouse ? Theme.withAlpha(Theme.primary, 0.14) : Theme.surfaceContainerHigh
            Text { anchors.centerIn: parent; text: "−"; color: Theme.surfaceTextVariant; font.pointSize: Theme.titleSmall; font.bold: true }
            MouseArea { id: decMa; anchors.fill: parent; hoverEnabled: true; onClicked: spinner.decrement() }
        }
        Rectangle {
            Layout.fillWidth: true; height: 24; radius: Theme.radiusSm
            color: Theme.surfaceContainerLow
            Text {
                anchors.centerIn: parent
                text: String(spinner.value).padStart(2, "0")
                color: Theme.surfaceText; font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge; font.bold: true
            }
        }
        Rectangle {
            width: 20; height: 24; radius: Theme.radiusSm
            color: incMa.containsMouse ? Theme.withAlpha(Theme.primary, 0.14) : Theme.surfaceContainerHigh
            Text { anchors.centerIn: parent; text: "+"; color: Theme.surfaceTextVariant; font.pointSize: Theme.titleSmall; font.bold: true }
            MouseArea { id: incMa; anchors.fill: parent; hoverEnabled: true; onClicked: spinner.increment() }
        }
    }
}
