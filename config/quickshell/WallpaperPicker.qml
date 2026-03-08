import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PopupWindow {
    id: root

    required property var barWindow

    implicitWidth:  barWindow ? barWindow.width : 100
    implicitHeight: stripH + labelH + 34
    color: "transparent"

    anchor.window: barWindow
    anchor.rect.x: 0
    anchor.rect.y: (barWindow && barWindow.screen)
        ? barWindow.screen.height - implicitHeight
        : 0
    anchor.rect.width:  1
    anchor.rect.height: 1

    // PopupWindow is an XDG popup — NOT a layer shell surface.
    // WlrLayershell does NOT apply here and will crash if used.
    // Keyboard focus for popups works differently: the compositor
    // gives focus automatically when the popup is mapped on most
    // compositors. On Hyprland we use a PanelWindow trick instead —
    // see keyCapture below.

    property bool  stripVisible: false
    property var   wallpapers:   []
    property string prevWall:    ""
    property int   highlightIdx: -1
    property int   selectedIdx:  -1

    readonly property int thumbW:  200
    readonly property int thumbH:  112
    readonly property int labelH:  22
    readonly property int stripH:  thumbH + 12

    function open() {
        root.wallpapers = []
        loadWalls.running = true
        snapshotProc.running = true
        root.visible = true
        stripVisible = true
        highlightIdx = selectedIdx >= 0 ? selectedIdx : 0
    }

    function close(confirm) {
        if (!confirm && prevWall !== "") applyWall(prevWall)
        else if (confirm && highlightIdx >= 0) selectedIdx = highlightIdx
        stripVisible = false
        closeTimer.start()
    }

    Timer {
        id: closeTimer
        interval: 280
        onTriggered: root.visible = false
    }

    function applyWall(path) {
        if (!path || path === "") return
        Quickshell.execDetached([
            "swww", "img",
            "--transition-type", "fade",
            "--transition-duration", "0.3",
            path
        ])
    }

    onHighlightIdxChanged: {
        if (highlightIdx >= 0 && highlightIdx < wallpapers.length) {
            applyWall(wallpapers[highlightIdx])
            filmstrip.positionViewAtIndex(highlightIdx, ListView.Contain)
        }
    }

    Process {
        id: loadWalls
        command: ["bash", "-c",
            "cat ~/.config/quickshell/wallpapers.txt 2>/dev/null | grep -v '^#' | grep -v '^$'"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                var s = root.wallpapers.slice()
                s.push(data.trim())
                root.wallpapers = s
            }
        }
    }

    Process {
        id: snapshotProc
        command: ["bash", "-c",
            "swww query 2>/dev/null | grep 'image:' | head -1 | sed 's/.*image: //'"]
        running: false
        stdout: SplitParser {
            onRead: data => { root.prevWall = data.trim() }
        }
    }

    // ── Backdrop click to cancel ─────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        z: 0
        onClicked: root.close(false)
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                root.highlightIdx = Math.max(root.highlightIdx - 1, 0)
            else
                root.highlightIdx = Math.min(root.highlightIdx + 1, root.wallpapers.length - 1)
        }
    }

    // ── Slide-up container ────────────────────────────────────────────────────
    Item {
        id: slideContainer
        width:  parent.width
        height: parent.height

        y: stripVisible ? 0 : height
        Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: "#e60d1117"
            border.color: "#445bcefa"
            border.width: 1
            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 1
                color: "#660df0ff"
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 2

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.highlightIdx >= 0 && root.wallpapers.length > root.highlightIdx
                    ? root.wallpapers[root.highlightIdx].replace(/.*\//, "")
                    : "select a wallpaper"
                color: Theme.cyan
                font.family: Theme.fontFamily
                font.pointSize: 7
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "scroll or hover to browse  ·  click to set  ·  esc to cancel"
                color: Theme.textDimmer
                font.family: Theme.fontFamily
                font.pointSize: 6
            }

            ListView {
                id: filmstrip
                Layout.fillWidth: true
                Layout.preferredHeight: root.stripH
                orientation: ListView.Horizontal
                spacing: 12
                clip: true
                model: root.wallpapers
                highlightMoveDuration: 180

                delegate: Item {
                    required property string modelData
                    required property int    index

                    width:  root.thumbW + 10
                    height: root.stripH

                    readonly property bool isHighlighted: root.highlightIdx === index
                    readonly property bool isSelected:    root.selectedIdx  === index

                    Rectangle {
                        anchors.centerIn: parent
                        width:  root.thumbW
                        height: root.thumbH
                        radius: 4
                        clip: true
                        color: "#1a1e28"

                        scale: isHighlighted ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150 } }

                        Image {
                            anchors.fill: parent
                            source: "file://" + modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: "transparent"
                            border.width: isHighlighted ? 3 : (isSelected ? 1 : 0)
                            border.color: isHighlighted ? Theme.cyan : "#55ffffff"
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: "black"
                            opacity: isHighlighted ? 0 : 0.45
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        z: 1
                        onEntered: root.highlightIdx = index
                        onClicked: root.close(true)
                    }
                }
            }
        }
    }

    // ── Keyboard capture overlay ─────────────────────────────────────────────
    // PopupWindow doesn't support WlrLayershell keyboard focus.
    // Instead we spawn a zero-size PanelWindow just to steal keyboard focus
    // while the picker is open, then relay the key events via a signal.
    // This is the standard workaround for Hyprland + QS popup keyboard input.
    signal keyPressed(int key)

    PanelWindow {
        id: keyCapture

        // Only exist / be visible while picker is open
        visible: root.visible && root.stripVisible

        // Zero-size, top-most, no exclusive zone — purely for key capture
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "quickshell:wallpaper-keys"
        exclusiveZone: 0
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        screen: root.barWindow ? root.barWindow.screen : undefined

        anchors { top: true }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => {
                root.keyPressed(event.key)
                event.accepted = true
            }
        }
    }

    onKeyPressed: key => {
        switch (key) {
            case Qt.Key_Escape:
                close(false); break
            case Qt.Key_Return:
            case Qt.Key_Enter:
                close(true); break
            case Qt.Key_Right:
            case Qt.Key_L:
                highlightIdx = Math.min(highlightIdx + 1, wallpapers.length - 1); break
            case Qt.Key_Left:
            case Qt.Key_H:
                highlightIdx = Math.max(highlightIdx - 1, 0); break
        }
    }
}
