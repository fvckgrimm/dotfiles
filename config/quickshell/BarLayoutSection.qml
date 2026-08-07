import QtQuick
import QtQuick.Layouts

// One section (LEFT / CENTER / RIGHT) of the bar layout editor: a labeled flow
// of draggable module chips with a whole-area drop zone that appends to the end.
Item {
    id: root

    required property string sectionName
    readonly property var modules: SettingsService.barLayout[root.sectionName]

    implicitWidth: 600
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: Theme.spacingSm

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: root.sectionName.toUpperCase() + "  (" + root.modules.length + ")"
                color: Theme.surfaceTextVariant
                font.family: Theme.fontFamily
                font.pointSize: Theme.labelSmall
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "click to toggle · drag to move"
                color: Theme.surfaceTextDim
                font.family: Theme.fontFamily
                font.pointSize: Theme.labelSmall
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: flow.implicitHeight + 8
            radius: Theme.radiusMd
            color: appendDrop.containsDrag ? Theme.withAlpha(Theme.primary, 0.12) : Theme.surfaceContainerLow
            border.color: appendDrop.containsDrag ? Theme.primary : "transparent"

            // Declared first so it sits underneath the chips (chips must win).
            DropArea {
                id: appendDrop
                anchors.fill: parent
                keys: ["barmodule"]
                onDropped: drop => SettingsService.moveBarModule(drop.source.moduleKey, root.sectionName, root.modules.length)
            }

            Flow {
                id: flow
                anchors { fill: parent; margins: 4 }
                spacing: 4

                Repeater {
                    model: root.modules
                    delegate: Item {
                        required property var modelData
                        required property int index
                        implicitWidth: chip.implicitWidth
                        implicitHeight: chip.implicitHeight

                        BarModuleChip {
                            id: chip
                            section: root.sectionName
                            moduleKey: parent.modelData
                            chipIndex: parent.index
                        }
                    }
                }
            }
        }
    }
}
