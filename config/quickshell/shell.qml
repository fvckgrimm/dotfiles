//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    // Kill any existing notification daemons so our server can register
    Process {
        command: ["bash", "-c", "pkill -x dunst; pkill -x mako; pkill -x swaync; pkill -x fnott; true"]
        running: true
    }

    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
    }
}
