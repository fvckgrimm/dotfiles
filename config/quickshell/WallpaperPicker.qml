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
    anchor.rect.y: (barWindow && barWindow.screen) ? barWindow.screen.height - implicitHeight : 0
    anchor.rect.width:  1
    anchor.rect.height: 1

    property bool  stripVisible: false
    property bool _closing: false
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
        if (_closing) return
        _closing = true
        if (!confirm && prevWall !== "") applyWall(prevWall)
        else if (confirm && highlightIdx >= 0) { selectedIdx = highlightIdx; applyWall(wallpapers[highlightIdx]) }
        stripVisible = false
        closeTimer.start()
    }

    Timer { id: closeTimer; interval: 280; onTriggered: { root.visible = false; root._closing = false } }

    function applyWall(path) {
        if (!path || path === "") return
        Quickshell.execDetached([
            "awww", "img",
            "-o", barWindow && barWindow.screen ? barWindow.screen.name : "DP-1",
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
        command: ["bash", "-c", "cat ~/.config/quickshell/wallpapers.txt 2>/dev/null | grep -v '^#' | grep -v '^$'"]
        running: false
        stdout: SplitParser { onRead: data => { var s = root.wallpapers.slice(); s.push(data.trim()); root.wallpapers = s } }
    }

    Process {
        id: snapshotProc
        command: ["bash", "-c", "awww query 2>/dev/null | grep 'image:' | head -1 | sed 's/.*image: //'"]
        running: false
        stdout: SplitParser { onRead: data => { root.prevWall = data.trim() } }
    }

    MouseArea {
        anchors.fill: parent
        z: 0
        onClicked: root.close(false)
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) root.highlightIdx = Math.max(root.highlightIdx - 1, 0)
            else root.highlightIdx = Math.min(root.highlightIdx + 1, root.wallpapers.length - 1)
        }
    }

    Item {
        id: slideContainer
        width:  parent.width
        height: parent.height
        y: stripVisible ? 0 : height
        Behavior on y { NumberAnimation { duration: Theme.motionSlow; easing.type: Theme.easingStandard } }

        Rectangle {
            anchors.fill: parent
            color: Theme.withAlpha(Theme.surfaceContainerLowest, 0.92)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingMd
            spacing: Theme.spacingXs

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.highlightIdx >= 0 && root.wallpapers.length > root.highlightIdx
                    ? root.wallpapers[root.highlightIdx].replace(/.*\//, "")
                    : "select a wallpaper"
                color: Theme.tertiary
                font.family: Theme.fontFamily
                font.pointSize: Theme.labelLarge
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "scroll or hover to browse  ·  click to set  ·  esc to cancel"
                color: Theme.surfaceTextDim
                font.family: Theme.fontFamily
                font.pointSize: Theme.labelSmall
            }

            ListView {
                id: filmstrip
                Layout.fillWidth: true
                Layout.preferredHeight: root.stripH
                orientation: ListView.Horizontal
                spacing: Theme.spacingLg
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
                        radius: Theme.radiusMd
                        clip: true
                        color: Theme.surfaceContainer

                        scale: isHighlighted ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.motionFast } }

                        Image {
                            anchors.fill: parent
                            source: "file://" + modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusMd
                            color: "transparent"
                            border.width: isHighlighted ? 2 : 0
                            border.color: Theme.tertiary
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusMd
                            color: "black"
                            opacity: isHighlighted ? 0 : 0.45
                            Behavior on opacity { NumberAnimation { duration: Theme.motionMedium } }
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

    signal keyPressed(int key)

    PanelWindow {
        id: keyCapture
        visible: root.visible && root.stripVisible
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
            Keys.onPressed: event => { root.keyPressed(event.key); event.accepted = true }
        }
    }

    onKeyPressed: key => {
        switch (key) {
            case Qt.Key_Escape: close(false); break
            case Qt.Key_Return:
            case Qt.Key_Enter: close(true); break
            case Qt.Key_Right:
            case Qt.Key_L: highlightIdx = Math.min(highlightIdx + 1, wallpapers.length - 1); break
            case Qt.Key_Left:
            case Qt.Key_H: highlightIdx = Math.max(highlightIdx - 1, 0); break
        }
    }
}
