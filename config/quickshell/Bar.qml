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

    CalendarPopup {
        id: calPopup
        visible: false
        anchor.window: bar
        anchor.rect.x: (bar.width - implicitWidth) / 2
        anchor.rect.y: bar.implicitHeight
        anchor.rect.width: 1
        anchor.rect.height: 1
    }

    ControlCenter {
        id: controlCenter
        visible: false
        anchor.window: bar
        anchor.rect.x: bar.width - implicitWidth - 12
        anchor.rect.y: bar.implicitHeight
        anchor.rect.width: 1
        anchor.rect.height: 1
    }

    WallpaperPicker {
        id: wallpaperPicker
        barWindow: bar
        visible: false
    }

    Connections {
        target: WallpaperService
        function onOpenChanged() {
            if (WallpaperService.open) wallpaperPicker.open()
            else wallpaperPicker.close(false)
        }
    }

    Connections {
        target: wallpaperPicker
        function onVisibleChanged() {
            if (!wallpaperPicker.visible) WallpaperService.open = false
        }
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

        Item {
            anchors.fill: parent

            // LEFT
            RowLayout {
                id: leftItems
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 6 }
                spacing: 2

                BarButton {
                    text: "\u{f0349}"
                    textColor: "#0df0ff"
                    borderColor: LauncherService.open ? "#550df0ff" : "transparent"
                    tooltipText: "App Launcher (Super+Space)"
                    onClicked: LauncherService.toggle()
                    onRightClicked: Quickshell.execDetached(Theme.drawerCmd)
                }

                BarButton {
                    text: "\u{f021d}"
                    textColor: Theme.purple
                    borderColor: WallpaperService.open ? "#55c792ea" : "transparent"
                    tooltipText: "Wallpaper Picker (Super+Shift+W)"
                    onClicked: WallpaperService.toggle()
                }

                WorkspacesWidget {}
                WeatherWidget {}
                TempWidget {}
            }

            // CENTER
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

                BarButton {
                    text: "󰒓"
                    textColor: "#c8d2e0"
                    borderColor: "transparent"
                    tooltipText: "Control Center"
                    onClicked: controlCenter.visible = !controlCenter.visible
                }

                // Todo button — toggles TodoWidget (a top-level PanelWindow in shell.qml)
                BarButton {
                    readonly property int pending: TodoService.pendingToday
                    text: pending > 0 ? ("󰄲 " + pending) : "󰄲"
                    textColor: pending > 0 ? "#e8b86a" : "#7984a4"
                    borderColor: TodoService.open
                        ? "#44e8b86a"
                        : (pending > 0 ? "#22e8b86a" : "transparent")
                    tooltipText: pending > 0
                        ? (pending + " task" + (pending > 1 ? "s" : "") + " remaining")
                        : "Todo  (Super+T)"
                    onClicked: TodoService.toggle()
                }

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

                BarButton {
                    text: "\udb80\udd00"
                    textColor: "#ff416c"
                    borderColor: "#55ff416c"
                    onClicked: Quickshell.execDetached(["bash", "-c", "$HOME/.config/hypr/scripts/screenshot_full"])
                    onRightClicked: Quickshell.execDetached(["bash", "-c", "$HOME/.config/hypr/scripts/screenshot_area"])
                    tooltipText: "Screenshot"
                }

                BarButton {
                    text: "\u{f0425}"
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
