//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick
ShellRoot {
    Process {
        command: ["bash", "-c", "pkill -x dunst; pkill -x mako; pkill -x swaync; pkill -x fnott; true"]
        running: true
    }
    IpcHandler {
        target: "wallpaper"
        function toggle() { WallpaperService.toggle() }
    }
    // qs ipc call launcher show
    // qs ipc call launcher toggle
    // qs ipc call launcher showMode "apps"   (also: calc, clip, emoji, words, kaomoji, pass, ssh)
    IpcHandler {
        target: "launcher"
        function show()      { LauncherService.show() }
        function toggle()    { LauncherService.toggle() }
        function apps()      { LauncherService.showMode("apps") }
        function clip()      { LauncherService.showMode("clip") }
        function emoji()     { LauncherService.showMode("emoji") }
        function calc()      { LauncherService.showMode("calc") }
        function words()     { LauncherService.showMode("words") }
        function kaomoji()   { LauncherService.showMode("kaomoji") }
        function pass()      { LauncherService.showMode("pass") }
        function ssh()       { LauncherService.showMode("ssh") }
    }
    // qs ipc call todo toggle
    IpcHandler {
        target: "todo"
        function toggle() { TodoService.toggle() }
    }
    // qs ipc call notifications toggle
    IpcHandler {
        target: "notifications"
        function toggle() { IpcBridge.toggleNotifCenter() }
    }
    // qs ipc call calendar toggle
    IpcHandler {
        target: "calendar"
        function toggle() { IpcBridge.toggleCalendar() }
    }
    // qs ipc call controlcenter toggle
    IpcHandler {
        target: "controlcenter"
        function toggle() { IpcBridge.toggleControlCenter() }
    }
    // qs ipc call theme set "catppuccin-mocha"  (or: default, catppuccin-macchiato,
    //   catppuccin-frappe, catppuccin-latte, dracula, rosepine)
    // qs ipc call theme cycle
    IpcHandler {
        target: "theme"
        function set(name: string) { SettingsService.theme = name }
        function cycle()            { SettingsService.cycleTheme() }
    }
    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
    }
    // LauncherPopup is a PanelWindow — needs to be top-level, not a Bar child.
    Variants {
        model: Quickshell.screens
        LauncherPopup {
            required property var modelData
            barWindow: null
            screen: modelData
        }
    }
    // TodoWidget is also a PanelWindow overlay — top-level, one per screen.
    Variants {
        model: Quickshell.screens
        TodoWidget {
            required property var modelData
            barWindow: null
            screen: modelData
        }
    }
}
