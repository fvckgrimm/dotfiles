import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PopupWindow {
    id: root

    required property var barWindow

    // Use null-checks (barWindow ?) to prevent the "width of undefined" crash during startup
    width: barWindow ? barWindow.width : 100
    height: stripH + labelH + 34
    color: "transparent"

    anchor.window: barWindow
    anchor.rect.x: 0
    anchor.rect.y: (barWindow && barWindow.screen) ? barWindow.screen.height - height : 0
    anchor.rect.width:  1
    anchor.rect.height: 1

    // ── State ────────────────────────────────────────────────────────────────
    property bool  stripVisible: false
    property var   wallpapers:   []
    property string prevWall:    ""       
    property int   highlightIdx: -1     
    property int   selectedIdx:  -1     

    readonly property int thumbW:  200
    readonly property int thumbH:  112
    readonly property int labelH:  22
    readonly property int stripH:  thumbH + 12

    // ── Open / Close Logic ──────────────────────────────────────────────────
    function open() {
        loadWalls.running = true
        snapshotProc.running = true
        
        root.visible = true          
        stripVisible = true     
        
        highlightIdx = selectedIdx >= 0 ? selectedIdx : 0
        
        // Ensure the internal key handler gets focus after the window is visible
        keyHandler.forceActiveFocus()
    }

    function close(confirm) {
        if (!confirm && prevWall !== "") {
            applyWall(prevWall)
        } else if (confirm && highlightIdx >= 0) {
            selectedIdx = highlightIdx
        }
        
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

    // ── Processes ───────────────────────────────────────────────────────────
    Process {
        id: loadWalls
        command: ["bash", "-c", "cat ~/.config/quickshell/wallpapers.txt 2>/dev/null | grep -v '^#' | grep -v '^$'"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                var s = root.wallpapers.slice()
                s.push(data.trim())
                root.wallpapers = s
            }
        }
        onRunningChanged: if (running) root.wallpapers = []
    }

    Process {
        id: snapshotProc
        command: ["bash", "-c", "swww query | grep 'image:' | head -1 | sed 's/.*image: //'"]
        running: false
        stdout: SplitParser {
            onRead: data => { root.prevWall = data.trim() }
        }
    }

    // ── Interaction Layer ────────────────────────────────────────────────────
    
    // Key capture logic
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                root.close(false)
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.close(true)
                event.accepted = true
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                highlightIdx = Math.min(highlightIdx + 1, wallpapers.length - 1)
                event.accepted = true
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                highlightIdx = Math.max(highlightIdx - 1, 0)
                event.accepted = true
            }
        }
    }

    // Backdrop / Scroll handling
    MouseArea {
        anchors.fill: parent
        onClicked: root.close(false)
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                highlightIdx = Math.max(highlightIdx - 1, 0)
            } else {
                highlightIdx = Math.min(highlightIdx + 1, wallpapers.length - 1)
            }
        }
    }

    // ── UI / Animation ───────────────────────────────────────────────────────
    Item {
        id: slideContainer
        width:  parent.width
        height: parent.height
        
        property real offset: stripVisible ? 0 : height
        y: offset
        Behavior on offset { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

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
                text: highlightIdx >= 0 && wallpapers.length > highlightIdx ? wallpapers[highlightIdx].replace(/.*\//, "") : "select a wallpaper"
                color: Theme.cyan
                font.family: Theme.fontFamily
                font.pointSize: 7
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "arrows/hl or scroll to browse  ·  enter to set  ·  esc to cancel"
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
                
                highlightMoveDuration: 200

                delegate: Item {
                    width: root.thumbW + 10
                    height: root.stripH

                    readonly property bool isHighlighted: root.highlightIdx === index
                    readonly property bool isSelected: root.selectedIdx === index

                    Rectangle {
                        id: thumbContainer
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
                            color: "black"
                            opacity: isHighlighted ? 0 : 0.4
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.highlightIdx = index
                        onClicked: root.close(true)
                    }
                }
            }
        }
    }
}
