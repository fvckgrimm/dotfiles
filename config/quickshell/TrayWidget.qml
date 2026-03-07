import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: trayRoot
    required property var barWindow   // passed from Bar.qml so anchor gets a real QS window

    implicitHeight: 22
    implicitWidth: Math.max(row.implicitWidth + 8, 0)
    color: "#661e1e28"
    radius: 2
    visible: SystemTray.items.values.length > 0

    RowLayout {
        id: row
        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 4 }
        spacing: 5

        Repeater {
            model: SystemTray.items

            delegate: Item {
                required property SystemTrayItem modelData
                implicitWidth: 18
                implicitHeight: 18

                // IconImage handles both XDG theme names and image paths
                // modelData.icon is already the correct source string
                IconImage {
                    id: iconImg
                    anchors.fill: parent
                    source: modelData.icon
                    implicitSize: 16
                    smooth: true
                }

                // Fallback text icon if image fails to load
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
                            trayMenu.open()   // no arguments
                        } else {
                            if (!modelData.onlyMenu) modelData.activate()
                            else trayMenu.open()
                        }
                    }
                }

                QsMenuAnchor {
                    id: trayMenu
                    menu: modelData.menu
                    // Must be a real Quickshell window, not a proxied one
                    anchor.window: trayRoot.barWindow
                    anchor.rect.x: {
                        // position below the tray icon
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
