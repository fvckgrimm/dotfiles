pragma Singleton
import Quickshell
import QtQuick

Scope {
    id: root

    property bool open: false
    property string mode: "apps"   // "apps" | "clip" | "emoji" | "calc" | "words"

    function toggle() { root.open = !root.open }
    function show()   { root.open = true }
    function hide()   { root.open = false }

    function showMode(m) {
        root.mode = m
        root.open = true
    }
}
