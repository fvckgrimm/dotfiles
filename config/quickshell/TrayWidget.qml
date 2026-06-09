import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: trayRoot
    required property var barWindow

    property bool expanded: false

    implicitHeight: 22
    implicitWidth: visibleItems ? (row.implicitWidth + 8) : 0
    
    readonly property bool visibleItems: SystemTray.items.values.length > 0
    visible: visibleItems

    color: "#661e1e28"
    radius: 2
    clip: true

    Behavior on implicitWidth {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    RowLayout {
        id: row
        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 4 }
        spacing: 5

        // Toggle arrow
        Item {
            implicitWidth: 16
            implicitHeight: 18

            Text {
                anchors.centerIn: parent
                text: trayRoot.expanded ? "\u{f054}" : "\u{f053}" // chevron-right : chevron-left
                font.family: Theme.fontFamily
                font.pointSize: 9
                color: trayRoot.expanded ? Theme.cyan : Theme.textDim

                Behavior on color { ColorAnimation { duration: 200 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: trayRoot.expanded = !trayRoot.expanded
            }
        }

        // Collapsible icons container
        RowLayout {
            id: iconsRow
            spacing: 5
            visible: trayRoot.expanded || opacity > 0
            opacity: trayRoot.expanded ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            Repeater {
                model: SystemTray.items

                delegate: Item {
                    required property SystemTrayItem modelData
                    implicitWidth: 18
                    implicitHeight: 18

                    IconImage {
                        id: iconImg
                        anchors.fill: parent
                        source: modelData.icon
                        implicitSize: 16
                        smooth: true
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: iconImg.status === Image.Error || iconImg.status === Image.Null
                        text: modelData.title ? modelData.title[0].toUpperCase() : "?"
                        color: "#c8d2e0"
                        font.pointSize: 8
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                trayMenu.open()
                            } else {
                                if (!modelData.onlyMenu) modelData.activate()
                                else trayMenu.open()
                            }
                        }
                    }

                    QsMenuAnchor {
                        id: trayMenu
                        menu: modelData.menu
                        anchor.window: trayRoot.barWindow
                        anchor.rect.x: {
                            var pt = mapToItem(null, 0, 0)
                            return pt.x
                        }
                        anchor.rect.y: trayRoot.barWindow.implicitHeight
                        anchor.rect.width: 18
                        anchor.rect.height: 1
                    }
                }
            }
        }
    }
}
