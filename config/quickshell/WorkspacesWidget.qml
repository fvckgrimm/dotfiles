import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// Hyprland workspaces — reactive via IPC, no polling needed
Item {
    id: wsRoot
    implicitHeight: 26
    implicitWidth: row.implicitWidth + Theme.spacingSm

    readonly property var wsNames: ["一","二","三","四","五","六","七","八","九","十"]

    RowLayout {
        id: row
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: Theme.spacingXs
        anchors.rightMargin: Theme.spacingXs
        spacing: Theme.spacingXs

        Repeater {
            model: Hyprland.workspaces
            delegate: Rectangle {
                required property var modelData
                readonly property bool isActive: modelData.id === Hyprland.focusedMonitor?.activeWorkspace?.id
                readonly property bool hasWindows: modelData.windowCount > 0
                implicitWidth: wsLabel.implicitWidth + Theme.spacingMd
                implicitHeight: 22
                radius: Theme.radiusMd
                color: isActive ? Theme.withAlpha(Theme.primary, 0.18) : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                Text {
                    id: wsLabel
                    anchors.centerIn: parent
                    text: (modelData.id >= 1 && modelData.id <= 10)
                          ? wsRoot.wsNames[modelData.id - 1]
                          : modelData.id.toString()
                    color: isActive ? Theme.primary : (hasWindows ? Theme.surfaceTextVariant : Theme.surfaceTextDim)
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.labelLarge
                    font.bold: true
                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = '" + modelData.id + "' })")
                    onWheel: wheel => {
                        if (wheel.angleDelta.y > 0) Hyprland.dispatch("hl.dsp.focus({ workspace = 'e+1' })")
                        else Hyprland.dispatch("hl.dsp.focus({ workspace = 'e-1' })")
                    }
                }
            }
        }
    }
}
