import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Notification center — popup panel showing history, triggered by bell icon in Bar.qml
// Positioned via anchor.* set by Bar.qml at instantiation time
PopupWindow {
    id: root

    

    implicitWidth: 380
    implicitHeight: Math.min(mainCol.implicitHeight + 24, 600)
    color: "transparent"

    onVisibleChanged: {
        if (visible) NotificationService.markAllRead()
    }

    // ── Card background ──────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: 8
        color: "#f00d1117"
        border.color: "#335bcefa"
        border.width: 1
        clip: true

        ColumnLayout {
            id: mainCol
            anchors { fill: parent; margins: 12 }
            spacing: 8

            // Header row
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰂚  Notifications"
                    color: "#0df0ff"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pointSize: 9
                    font.bold: true
                    Layout.fillWidth: true
                }

                // Clear all button
                Rectangle {
                    implicitWidth: clearLabel.implicitWidth + 14
                    implicitHeight: 20
                    radius: 2
                    color: clearMa.containsMouse ? "#33ff416c" : "transparent"
                    border.color: "#55ff416c"
                    border.width: 1
                    visible: ( NotificationService.notifications ? NotificationService.notifications.length : 0) > 0

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Clear all"
                        color: "#ff416c"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pointSize: 7
                    }
                    MouseArea {
                        id: clearMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: NotificationService.clearAll()
                    }
                }

                // Close center
                Text {
                    text: "✕"
                    color: "#7984a4"
                    font.pointSize: 9
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.visible = false
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#1a5bcefa"
            }

            // Empty state
            Item {
                Layout.fillWidth: true
                implicitHeight: 60
                visible: ( NotificationService.notifications ? NotificationService.notifications.length : 0) === 0

                Text {
                    anchors.centerIn: parent
                    text: "No notifications"
                    color: "#555e7a"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pointSize: 8
                }
            }

            // Notification list
            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: Math.min(contentCol.implicitHeight, 480)
                contentHeight: contentCol.implicitHeight
                clip: true
                visible: ( NotificationService.notifications ? NotificationService.notifications.length : 0) > 0

                ColumnLayout {
                    id: contentCol
                    width: flick.width
                    spacing: 6

                    Repeater {
                        model: NotificationService.notifications ?? []

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: itemCol.implicitHeight + 16
                            radius: 4
                            color: itemMa.containsMouse ? "#1a5bcefa" : "#0d5bcefa"
                            border.color: "#1a5bcefa"
                            border.width: 1

                            // Urgency stripe
                            Rectangle {
                                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 1 }
                                width: 2
                                radius: 2
                                color: {
                                    var u = modelData.urgency ?? 1
                                    if (u === 2) return "#ff0000"
                                    if (u === 0) return "#555e7a"
                                    return "#0df0ff"
                                }
                            }

                            ColumnLayout {
                                id: itemCol
                                anchors { fill: parent; margins: 8; leftMargin: 14 }
                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: modelData.appName
                                        color: "#7984a4"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pointSize: 7
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.time
                                        color: "#444d62"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pointSize: 7
                                    }

                                    Text {
                                        text: "✕"
                                        color: "#555e7a"
                                        font.pointSize: 7
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: NotificationService.dismiss(modelData)
                                        }
                                    }
                                }

                                Text {
                                    text: modelData.summary
                                    color: "#c8d2e0"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 8
                                    font.bold: true
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    visible: text !== ""
                                }

                                Text {
                                    text: modelData.body
                                    color: "#7984a4"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 7
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    textFormat: Text.PlainText
                                    maximumLineCount: 4
                                    elide: Text.ElideRight
                                    visible: text !== ""
                                }
                            }

                            MouseArea {
                                id: itemMa
                                anchors.fill: parent
                                hoverEnabled: true
                                // Don't steal clicks from child buttons
                                propagateComposedEvents: true
                                onClicked: mouse => mouse.accepted = false
                            }
                        }
                    }
                }
            }
        }
    }
}
