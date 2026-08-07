pragma Singleton
import Quickshell
import QtQuick

// IpcBridge — plain signal relay. shell.qml's IpcHandler targets live at
// the top level and can't reach the popups owned by each per-screen Bar
// instance directly, so IPC calls fire a signal here and every Bar
// listens via Connections. Add one signal per new keybind-able popup.
Scope {
    id: root
    signal toggleNotifCenter()
    signal toggleCalendar()
    signal toggleControlCenter()
}
