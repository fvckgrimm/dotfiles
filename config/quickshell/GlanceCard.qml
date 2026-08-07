import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// GlanceCard — self-polling stat card for the Dashboard "at a glance" tab.
// Runs `command` every `pollInterval` ms; `transform` receives the full stdout
// (splitMarker: "" so multiline output arrives in one onRead) and returns
// { value, pct, sub } to drive the card.
Item {
    id: root

    property string label
    property string icon
    property string iconColor: Theme.primary
    property string accent: Theme.primary
    property var    command: []
    property int    pollInterval: 5000
    property var    transformFn: null   // (stdout) => ({ value, pct, sub })
    property string value: "…"
    property int    pct: -1           // -1 hides the progress bar
    property string sub: ""
    property var    bars: []          // [{ label, pct }] — vertical per-core strip
    property bool   running: true

    signal clicked()                  // emit after every poll? no — user clicks the card

    function repoll() { proc.running = true }

    implicitHeight: col.implicitHeight + Theme.spacingMd * 2
    implicitWidth:  col.implicitWidth  + Theme.spacingMd * 2

    Process {
        id: proc
        command: root.command
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                if (!root.transformFn) return
                try {
                    var r = root.transformFn(data)
                    if (r && typeof r === "object") {
                        if (r.value !== undefined) root.value = r.value
                        if (r.pct   !== undefined) root.pct   = r.pct
                        if (r.sub   !== undefined) root.sub   = r.sub
                        if (r.bars  !== undefined) root.bars  = r.bars
                    }
                } catch (e) {
                    console.log("GlanceCard '" + root.label + "' parse error: " + e)
                }
            }
        }
    }

    Timer {
        interval: root.pollInterval
        running: root.running
        repeat: true
        onTriggered: proc.running = true
    }

    Component.onCompleted: proc.running = true

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.radiusMd
        color: Theme.surfaceContainerLow

        ColumnLayout {
            id: col
            anchors { fill: parent; margins: Theme.spacingMd }
            spacing: Theme.spacingXs

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSm

                Text {
                    text: root.icon
                    color: root.iconColor
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.titleSmall
                }
                Text {
                    text: root.label
                    color: Theme.surfaceTextVariant
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.labelLarge
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: root.value
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.bodyMedium
                    font.bold: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.pct >= 0
                spacing: Theme.spacingSm

                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: Theme.radiusFull
                    color: Theme.surfaceContainerHigh

                    Rectangle {
                        width: parent.width * Math.min(100, Math.max(0, root.pct)) / 100
                        height: parent.height
                        radius: Theme.radiusFull
                        color: root.accent
                        Behavior on width { NumberAnimation { duration: Theme.motionMedium } }
                    }
                }
                Text {
                    text: root.pct >= 0 ? root.pct + "%" : ""
                    color: Theme.surfaceTextDim
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.labelSmall
                    visible: root.sub === ""
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.sub !== ""
                text: root.sub
                color: Theme.surfaceTextDim
                font.family: Theme.fontFamily
                font.pointSize: Theme.labelSmall
                elide: Text.ElideRight
            }

            // Per-core / segment strip (btop-style vertical bars)
            RowLayout {
                Layout.fillWidth: true
                visible: root.bars.length > 0
                spacing: 3
                Layout.maximumHeight: 28

                Repeater {
                    model: root.bars
                    delegate: Item {
                        Layout.preferredWidth: 12
                        Layout.preferredHeight: 28
                        implicitWidth: 12
                        implicitHeight: 28

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 2

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 2
                                color: Theme.surfaceContainerHigh

                                Rectangle {
                                    width: parent.width
                                    height: parent.height * Math.min(100, Math.max(0, modelData.pct)) / 100
                                    anchors.bottom: parent.bottom
                                    radius: 2
                                    color: modelData.pct >= 80 ? Theme.error
                                         : modelData.pct >= 50 ? Theme.warning
                                         : Theme.primary
                                    Behavior on height { NumberAnimation { duration: Theme.motionMedium } }
                                }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.label
                                color: Theme.surfaceTextDim
                                font.family: Theme.fontFamily
                                font.pointSize: 7
                            }
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
