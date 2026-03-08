pragma Singleton
import Quickshell
import QtQuick

Scope {
    id: root

    property bool open: false

    function toggle() {
        root.open = !root.open
    }
}
