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
    // qs ipc call launcher showMode "apps"   (also: calc, clip, emoji, words)
    IpcHandler {
        target: "launcher"
        function show()      { LauncherService.show() }
        function toggle()    { LauncherService.toggle() }
        function apps()      { LauncherService.showMode("apps") }
        function clip()      { LauncherService.showMode("clip") }
        function emoji()     { LauncherService.showMode("emoji") }
        function calc()      { LauncherService.showMode("calc") }
        function words()     { LauncherService.showMode("words") }
    }

    // qs ipc call todo toggle
    IpcHandler {
        target: "todo"
        function toggle() { TodoService.toggle() }
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
