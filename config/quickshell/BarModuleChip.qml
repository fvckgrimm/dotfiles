import QtQuick
import QtQuick.Layouts

// A single module chip in the bar layout editor. Drag it to another section
// (or slot within a section) to move it; click it to toggle visibility.
Item {
    id: root

    required property string section
    required property string moduleKey
    required property int chipIndex

    readonly property var meta: SettingsService.moduleMeta(root.moduleKey)
    readonly property bool active: SettingsService.isModuleVisible(root.moduleKey)
    readonly property bool dragging: ma.drag.active

    implicitWidth: 132
    implicitHeight: 22

    Drag.active: ma.drag.active
    Drag.source: root
    Drag.keys: ["barmodule"]
    Drag.hotSpot.x: root.width / 2
    Drag.hotSpot.y: root.height / 2

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.radiusSm
        color: root.dragging ? Theme.withAlpha(Theme.primary, 0.25)
             : (ma.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer)
        border.color: root.dragging ? Theme.primary : "transparent"
        opacity: root.active ? 1 : 0.45

        RowLayout {
            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
            spacing: Theme.spacingSm

            Text {
                text: root.meta.icon
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pointSize: Theme.titleSmall
            }

            Text {
                text: root.meta.name
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pointSize: Theme.labelSmall
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        drag.target: root
        drag.threshold: 4
        onPressed: {
            SettingsService.editorDragging = true
            root.z = 100
        }
        onReleased: {
            root.Drag.drop()
            root.Drag.active = false
            root.z = 0
            SettingsService.editorDragging = false
        }
        onCanceled: { root.Drag.active = false; root.z = 0; SettingsService.editorDragging = false }
        onClicked: SettingsService.toggleModuleVisible(root.moduleKey)
    }

    DropArea {
        id: drop
        anchors.fill: parent
        keys: ["barmodule"]
        onDropped: drop => SettingsService.moveBarModule(drop.source.moduleKey, root.section, root.chipIndex)
    }
}
