import QtQuick
import QtQuick.Layouts

// Simple +/- spinner for hour or minute values
// Properties: value, min, max, step
// Bind to value directly — it updates on click
Item {
    id: spinner

    property int value: 0
    property int min:   0
    property int max:   23
    property int step:  1

    implicitWidth:  72
    implicitHeight: 24

    function increment() {
        var v = value + step
        if (v > max) v = min
        value = v
    }

    function decrement() {
        var v = value - step
        if (v < min) v = max
        value = v
    }

    RowLayout {
        anchors.fill: parent
        spacing: 2

        Rectangle {
            width: 20; height: 24; radius: 3
            color: decMa.containsMouse ? "#220df0ff" : "#1a1e2e"
            border.color: "#33ffffff"; border.width: 1
            Text { anchors.centerIn: parent; text: "−"; color: "#7984a4"; font.pointSize: 9; font.bold: true }
            MouseArea { id: decMa; anchors.fill: parent; hoverEnabled: true; onClicked: spinner.decrement() }
        }

        Rectangle {
            Layout.fillWidth: true; height: 24; radius: 3
            color: "#0d1117"
            border.color: "#22ffffff"; border.width: 1
            Text {
                anchors.centerIn: parent
                text: String(spinner.value).padStart(2, "0")
                color: "#d8e0f0"; font.family: Theme.fontFamily; font.pointSize: 8; font.bold: true
            }
        }

        Rectangle {
            width: 20; height: 24; radius: 3
            color: incMa.containsMouse ? "#220df0ff" : "#1a1e2e"
            border.color: "#33ffffff"; border.width: 1
            Text { anchors.centerIn: parent; text: "+"; color: "#7984a4"; font.pointSize: 9; font.bold: true }
            MouseArea { id: incMa; anchors.fill: parent; hoverEnabled: true; onClicked: spinner.increment() }
        }
    }
}
