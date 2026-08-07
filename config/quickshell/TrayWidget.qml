import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: trayRoot
    required property var barWindow
    property bool expanded: false
    implicitHeight: 26
    implicitWidth: visibleItems ? (row.implicitWidth + Theme.spacingMd) : 0

    readonly property bool visibleItems: SystemTray.items.values.length > 0
    visible: visibleItems

    Behavior on implicitWidth { NumberAnimation { duration: Theme.motionMedium; easing.type: Theme.easingStandard } }

    RowLayout {
        id: row
        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: Theme.spacingXs }
        spacing: Theme.spacingSm

        Item {
            implicitWidth: 16
            implicitHeight: 20
            Text {
                anchors.centerIn: parent
                text: trayRoot.expanded ? "\u{f054}" : "\u{f053}"
                font.family: Theme.fontFamily
                font.pointSize: Theme.labelLarge
                color: trayRoot.expanded ? Theme.primary : Theme.surfaceTextVariant
                Behavior on color { ColorAnimation { duration: Theme.motionMedium } }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: trayRoot.expanded = !trayRoot.expanded
            }
        }

        RowLayout {
            id: iconsRow
            spacing: Theme.spacingSm
            visible: trayRoot.expanded || opacity > 0
            opacity: trayRoot.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.motionMedium } }

            Repeater {
                model: SystemTray.items
                delegate: Item {
                    required property SystemTrayItem modelData
                    implicitWidth: 18
                    implicitHeight: 18
                    IconImage { id: iconImg; anchors.fill: parent; source: modelData.icon; implicitSize: 16; smooth: true }
                    Text {
                        anchors.centerIn: parent
                        visible: iconImg.status === Image.Error || iconImg.status === Image.Null
                        text: modelData.title ? modelData.title[0].toUpperCase() : "?"
                        color: Theme.surfaceText
                        font.pointSize: Theme.labelLarge
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) trayMenu.open()
                            else { if (!modelData.onlyMenu) modelData.activate(); else trayMenu.open() }
                        }
                    }
                    QsMenuAnchor {
                        id: trayMenu
                        menu: modelData.menu
                        anchor.window: trayRoot.barWindow
                        anchor.rect.x: { var pt = mapToItem(null, 0, 0); return pt.x }
                        anchor.rect.y: trayRoot.barWindow.implicitHeight
                        anchor.rect.width: 18
                        anchor.rect.height: 1
                    }
                }
            }
        }
    }
}
