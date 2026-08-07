import QtQuick
import QtQuick.Layouts

// Drag-and-drop editor for the bar layout (left / center / right sections).
// Drag chips between sections or within a section; click a chip to toggle the
// module's visibility. Changes persist via SettingsService.
Item {
    id: root
    implicitWidth: 600
    implicitHeight: editorCol.implicitHeight

    ColumnLayout {
        id: editorCol
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: Theme.spacingMd

        BarLayoutSection { Layout.fillWidth: true; sectionName: "left" }
        BarLayoutSection { Layout.fillWidth: true; sectionName: "center" }
        BarLayoutSection { Layout.fillWidth: true; sectionName: "right" }
    }
}
