import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// Hyprland workspaces — reactive via IPC, no polling needed
Rectangle {
    id: wsRoot
    implicitHeight: 22
    implicitWidth: row.implicitWidth + 8
    color: "#991e1e28"
    radius: 4

    // Japanese numerals matching your old waybar config
    readonly property var wsNames: ["一","二","三","四","五","六","七","八","九","十"]

    RowLayout {
        id: row
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 2

        Repeater {
            model: Hyprland.workspaces

            delegate: Rectangle {
                required property var modelData

                readonly property bool isActive: modelData.id === Hyprland.focusedMonitor?.activeWorkspace?.id
                readonly property bool hasWindows: modelData.windowCount > 0

                implicitWidth: wsLabel.implicitWidth + 10
                implicitHeight: 18
                radius: 2
                color: isActive ? "#330df0ff" : "transparent"

                // bottom underline for active
                Rectangle {
                    visible: isActive
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    height: 2
                    color: "#b30df0ff"
                    radius: 1
                }

                Text {
                    id: wsLabel
                    anchors.centerIn: parent
                    // Access wsNames from the outer Rectangle via wsRoot id
                    text: (modelData.id >= 1 && modelData.id <= 10)
                          ? wsRoot.wsNames[modelData.id - 1]
                          : modelData.id.toString()
                    color: isActive ? "#0df0ff" : (hasWindows ? "#9aa5c4" : "#7984a4")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pointSize: 8
                    font.bold: true

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace " + modelData.id)
                    onWheel: wheel => {
                        if (wheel.angleDelta.y > 0)
                            Hyprland.dispatch("workspace e+1")
                        else
                            Hyprland.dispatch("workspace e-1")
                    }
                }
            }
        }
    }
}
