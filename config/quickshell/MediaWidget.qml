import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Bar media module — album art + track line + prev/play/next, shown only
// while an MPRIS player exists. Click the pill (not the control buttons) to
// open the expanded view; scroll to skip. The pill auto-hides a few seconds
// after playback pauses. All state comes from the MediaService singleton.
Item {
    id: root
    required property var barWindow
    property bool expanded: false
    property bool dismissed: false

    implicitHeight: 24
    implicitWidth: visible ? content.implicitWidth + Theme.spacingSm : 0
    visible: MediaService.hasPlayer && !root.dismissed

    readonly property string label: {
        if (!MediaService.hasPlayer) return ""
        var a = MediaService.artist, t = MediaService.title
        var info = (a && t) ? (a + " - " + t) : (t || a || MediaService.identity)
        if (info.length > 34) info = info.substring(0, 34) + "…"
        return info
    }

    // If playback stops and stays stopped, collapse back to "normal" state
    // instead of keeping the image + title pinned in the bar. Polls every
    // second rather than relying only on the change signal, which some
    // players deliver lazily or not at all.
    property int pausedFor: 0
    Timer {
        id: idleTimer
        interval: 1000
        repeat: true
        running: root.visible && MediaService.hasPlayer && !MediaService.isPlaying
        onRunningChanged: if (running) root.pausedFor = 0
        onTriggered: {
            root.pausedFor++
            if (root.pausedFor >= 12) root.dismissed = true
        }
    }
    Connections {
        target: MediaService
        function onIsPlayingChanged() {
            root.pausedFor = 0
            if (MediaService.isPlaying) root.dismissed = false
        }
    }
    onDismissedChanged: if (root.dismissed) root.expanded = false

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: Theme.radiusFull
        color: pillMa.containsMouse ? Theme.withAlpha(Theme.surfaceContainerHigh, 0.85) : Theme.bgModule
        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    }

    // Click-to-expand + scroll-to-skip. Declared BEFORE the content row so
    // the control buttons (later siblings) sit on top and win their clicks.
    MouseArea {
        id: pillMa
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) MediaService.previous()
            else MediaService.next()
        }
    }

    RowLayout {
        id: content
        anchors { fill: parent; leftMargin: Theme.spacingSm; rightMargin: Theme.spacingSm }
        spacing: Theme.spacingSm

        Rectangle {
            Layout.preferredWidth: 20; Layout.preferredHeight: 20
            radius: Theme.radiusSm; clip: true
            color: Theme.surfaceContainerHigh

            Image {
                anchors.fill: parent
                source: MediaService.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: MediaService.artUrl !== ""
            }
            Text {
                anchors.centerIn: parent
                text: "\u{f001}"  // music note placeholder while no art
                color: Theme.tertiary
                font.family: Theme.fontFamily
                font.pointSize: Theme.labelSmall
                visible: MediaService.artUrl === ""
            }
        }

        Text {
            text: root.label
            color: MediaService.isPlaying ? Theme.surfaceText : Theme.surfaceTextVariant
            font.family: Theme.fontFamily
            font.pointSize: Theme.labelLarge
            elide: Text.ElideRight
            Layout.maximumWidth: 200
        }

        RowLayout {
            spacing: Theme.spacingXs
            MediaIconButton {
                glyph: "\u{f048}"  // fa step-backward
                tooltipText: "Previous"
                onClicked: MediaService.previous()
            }
            MediaIconButton {
                glyph: MediaService.isPlaying ? "\u{f04c}" : "\u{f04b}"  // fa pause/play
                tooltipText: MediaService.isPlaying ? "Pause" : "Play"
                onClicked: MediaService.toggle()
            }
            MediaIconButton {
                glyph: "\u{f051}"  // fa step-forward
                tooltipText: "Next"
                onClicked: MediaService.next()
            }
        }
    }

    // ── Expanded "now playing" popup ─────────────────────────────────────
    // Fullscreen transparent popup: a backdrop catches clicks anywhere to
    // close, and the card is positioned just below the pill.
    PopupWindow {
        id: mediaPopup
        readonly property int cardWidth: 360
        readonly property int cardHeight: cardCol.implicitHeight + Theme.spacingXl * 2
        implicitWidth: root.barWindow ? root.barWindow.width : 1
        implicitHeight: root.barWindow ? root.barWindow.screen.height : 1
        color: "transparent"
        visible: root.expanded

        anchor.window: root.barWindow
        anchor.rect.x: 0
        anchor.rect.y: 0
        anchor.rect.width: 1
        anchor.rect.height: 1

        // Keep the progress bar live while the popup is open.
        Timer {
            running: mediaPopup.visible && MediaService.hasPlayer
            interval: 500
            repeat: true
            onTriggered: MediaService.poll()
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.withAlpha("#000000", 0.25)
            MouseArea { anchors.fill: parent; onClicked: root.expanded = false }
        }

        Rectangle {
            width: mediaPopup.cardWidth
            height: mediaPopup.cardHeight
            radius: Theme.radiusXl
            color: Theme.cardColor()
            border.color: Theme.cardBorder()
            border.width: 1
            clip: true
            x: {
                var pt = root.mapToItem(null, 0, 0)
                return Math.max(8, Math.min(pt.x + root.width - mediaPopup.cardWidth,
                                            (root.barWindow ? root.barWindow.width : 0) - mediaPopup.cardWidth - 8))
            }
            y: (root.barWindow ? root.barWindow.implicitHeight : 0) + 4

            MouseArea { anchors.fill: parent; onClicked: {} }

            ColumnLayout {
                id: cardCol
                anchors { fill: parent; margins: Theme.spacingXl }
                spacing: Theme.spacingMd

                // Album art — click to raise the player.
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 280
                    radius: Theme.radiusMd
                    clip: true
                    color: Theme.surfaceContainerHigh

                    Image {
                        anchors.fill: parent
                        source: MediaService.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        visible: MediaService.artUrl !== ""
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "\u{f001}"
                        color: Theme.tertiary
                        font.family: Theme.fontFamily
                        font.pointSize: 40
                        visible: MediaService.artUrl === ""
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaService.raise()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingXs

                    Text {
                        Layout.fillWidth: true
                        text: MediaService.title || MediaService.identity
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.bodyLarge
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: (MediaService.artist + (MediaService.album ? " · " + MediaService.album : "")).trim()
                        color: Theme.surfaceTextVariant
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.labelMedium
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: MediaService.identity
                        color: Theme.surfaceTextDim
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.labelSmall
                        elide: Text.ElideRight
                    }
                }

                // Seek bar (same drag logic as ControlCenter).
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSm

                    Text {
                        text: MediaService.format(MediaService.position)
                        color: Theme.surfaceTextVariant
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.labelSmall
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 16
                        property real frac: MediaService.length > 0
                            ? Math.max(0, Math.min(1, MediaService.position / MediaService.length))
                            : 0
                        property real dragFrac: -1
                        property real shown: dragFrac >= 0 ? dragFrac : frac

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 4
                            radius: Theme.radiusFull
                            color: Theme.surfaceContainerHigh
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 4
                            radius: Theme.radiusFull
                            color: Theme.tertiary
                            width: parent.shown * parent.width
                        }
                        Rectangle {
                            x: parent.shown * (parent.width - width)
                            anchors.verticalCenter: parent.verticalCenter
                            width: 12; height: 12; radius: Theme.radiusFull
                            color: Theme.tertiary
                            border.color: Theme.surfaceContainerLowest
                            border.width: 2
                        }
                        MouseArea {
                            anchors.fill: parent
                            onPressed: mouse => { parent.dragFrac = Math.max(0, Math.min(1, mouse.x / width)) }
                            onPositionChanged: mouse => { if (pressed) parent.dragFrac = Math.max(0, Math.min(1, mouse.x / width)) }
                            onReleased: mouse => {
                                MediaService.seekToFraction(parent.dragFrac)
                                parent.dragFrac = -1
                            }
                        }
                    }

                    Text {
                        text: MediaService.format(MediaService.length)
                        color: Theme.surfaceTextVariant
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.labelSmall
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingMd

                    Item { Layout.fillWidth: true }

                    MediaIconButton {
                        size: 30
                        glyph: "\u{f048}"
                        tooltipText: "Previous"
                        onClicked: MediaService.previous()
                    }
                    MediaIconButton {
                        size: 38
                        glyph: MediaService.isPlaying ? "\u{f04c}" : "\u{f04b}"
                        tooltipText: MediaService.isPlaying ? "Pause" : "Play"
                        colorInactive: Theme.tertiary
                        onClicked: MediaService.toggle()
                    }
                    MediaIconButton {
                        size: 30
                        glyph: "\u{f051}"
                        tooltipText: "Next"
                        onClicked: MediaService.next()
                    }

                    Item { Layout.fillWidth: true }

                    MediaIconButton {
                        size: 24
                        glyph: "\u{f08e}"  // fa external-link — open the player
                        tooltipText: "Open " + MediaService.identity
                        onClicked: MediaService.raise()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    text: "click art to open player  ·  click outside to close"
                    color: Theme.surfaceTextDim
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.labelSmall
                }
            }
        }
    }
}
