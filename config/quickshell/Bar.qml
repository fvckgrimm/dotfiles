import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: bar
    required property var screen

    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top

    anchors { top: true; left: true; right: true }
    implicitHeight: 30
    color: "transparent"
    exclusiveZone: implicitHeight

    NotificationPopup { id: notifPopup; barWindow: bar }

    NotificationCenter {
        id: notifCenter
        visible: false
        anchor.window: bar
        anchor.rect.x: bar.width - implicitWidth - 12
        anchor.rect.y: bar.implicitHeight
        anchor.rect.width: 1
        anchor.rect.height: 1
    }

    // Calendar popup anchored below clock
    CalendarPopup {
        id: calPopup
        visible: false
        anchor.window: bar
        anchor.rect.x: (bar.width - implicitWidth) / 2
        anchor.rect.y: bar.implicitHeight
        anchor.rect.width: 1
        anchor.rect.height: 1
    }

    // Control center popup anchored below bar right
    ControlCenter {
        id: controlCenter
        visible: false
        anchor.window: bar
        anchor.rect.x: bar.width - implicitWidth - 12
        anchor.rect.y: bar.implicitHeight
        anchor.rect.width: 1
        anchor.rect.height: 1
    }

    Rectangle {
        anchors.fill: parent
        color: "#d90d1117"
        border.color: "#335bcefa"
        border.width: 1

        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1
            color: "#330af0ff"
        }

        // True 3-column layout: left/center/right all relative to bar width
        Item {
            anchors.fill: parent

            // LEFT
            RowLayout {
                id: leftItems
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 6 }
                spacing: 2

                BarButton {
                    text: ""
                    textColor: "#0df0ff"
                    borderColor: "#550df0ff"
                    onClicked: Quickshell.execDetached(["fuzzel"])
                    onRightClicked: Quickshell.execDetached(["nwg-drawer"])
                    tooltipText: "App Launcher"
                }
                WorkspacesWidget {}
                WeatherWidget {}
                TempWidget {}
            }

            // CENTER — truly centered regardless of left/right widths
            ClockWidget {
                anchors.centerIn: parent
                onClockClicked: calPopup.visible = !calPopup.visible
            }

            // RIGHT
            RowLayout {
                id: rightItems
                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 6 }
                spacing: 2

                StorageWidget {}
                MemoryWidget {}
                CpuWidget {}
                BatteryWidget {}
                AudioWidget {}
                NetworkWidget {}
                MediaWidget {}

                // Control center button
                BarButton {
                    text: "󰒓"
                    textColor: "#c8d2e0"
                    borderColor: "transparent"
                    tooltipText: "Control Center"
                    onClicked: controlCenter.visible = !controlCenter.visible
                }

                // Notification bell
                BarButton {
                    readonly property int count: NotificationService.unreadCount ?? 0
                    text: count > 0 ? ("󰂚 " + count) : "󰂜"
                    textColor: count > 0 ? "#ffcc00" : "#7984a4"
                    borderColor: count > 0 ? "#55ffcc00" : "transparent"
                    tooltipText: count > 0
                        ? (count + " notification" + (count > 1 ? "s" : ""))
                        : "No notifications"
                    onClicked: notifCenter.visible = !notifCenter.visible
                }

                // Screenshot
                BarButton {
                    text: ""
                    textColor: "#ff416c"
                    borderColor: "#55ff416c"
                    onClicked: Quickshell.execDetached(["bash", "-c", "$HOME/.config/hypr/scripts/screenshot_full"])
                    onRightClicked: Quickshell.execDetached(["bash", "-c", "$HOME/.config/hypr/scripts/screenshot_area"])
                    tooltipText: "Screenshot"
                }

                // Power
                BarButton {
                    text: ""
                    textColor: "#ff416c"
                    borderColor: "transparent"
                    onClicked: Quickshell.execDetached(["wlogout"])
                    tooltipText: "Power Menu"
                }

                TrayWidget { barWindow: bar }
            }
        }
    }
}
