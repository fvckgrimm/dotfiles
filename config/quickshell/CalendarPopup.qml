import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PopupWindow {
    id: root
    implicitWidth: 280
    implicitHeight: calCol.implicitHeight + Theme.spacingXl * 2
    color: "transparent"

    property int displayYear: new Date().getFullYear()
    property int displayMonth: new Date().getMonth()
    property int todayDay: new Date().getDate()
    property int todayMonth: new Date().getMonth()
    property int todayYear: new Date().getFullYear()

    readonly property var monthNames: ["January","February","March","April","May","June",
                                       "July","August","September","October","November","December"]
    readonly property var dayNames: ["Su","Mo","Tu","We","Th","Fr","Sa"]

    function updateToday() {
        const now = new Date();
        root.todayDay = now.getDate();
        root.todayMonth = now.getMonth();
        root.todayYear = now.getFullYear();
    }

    onVisibleChanged: { if (visible) updateToday() }

    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.updateToday() }

    function daysInMonth(year, month) { return new Date(year, month + 1, 0).getDate() }
    function firstDayOfMonth(year, month) { return new Date(year, month, 1).getDay() }
    function prevMonth() { if (displayMonth === 0) { displayMonth = 11; displayYear-- } else displayMonth-- }
    function nextMonth() { if (displayMonth === 11) { displayMonth = 0; displayYear++ } else displayMonth++ }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.spacingXs
        radius: Theme.radiusXl
        color: Theme.cardColor()
        border.color: Theme.cardBorder()
        border.width: 1

        ColumnLayout {
            id: calCol
            anchors { fill: parent; margins: Theme.spacingLg }
            spacing: Theme.spacingMd

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "‹"; color: Theme.primary; font.pointSize: Theme.titleLarge; font.bold: true
                    MouseArea { anchors.fill: parent; onClicked: root.prevMonth() }
                }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.monthNames[root.displayMonth] + "  " + root.displayYear
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.bodyLarge
                    font.bold: true
                }
                Text {
                    text: "›"; color: Theme.primary; font.pointSize: Theme.titleLarge; font.bold: true
                    MouseArea { anchors.fill: parent; onClicked: root.nextMonth() }
                }
            }

            Grid {
                columns: 7
                Layout.fillWidth: true
                spacing: Theme.spacingXs

                Repeater {
                    model: root.dayNames
                    delegate: Text {
                        required property string modelData
                        width: (calCol.width - Theme.spacingLg) / 7
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Theme.surfaceTextDim
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.labelLarge
                        font.bold: true
                    }
                }

                Repeater {
                    model: root.firstDayOfMonth(root.displayYear, root.displayMonth)
                    delegate: Item { width: (calCol.width - Theme.spacingLg) / 7; height: 24 }
                }

                Repeater {
                    model: root.daysInMonth(root.displayYear, root.displayMonth)
                    delegate: Rectangle {
                        id: dayRect
                        required property int index
                        readonly property int day: index + 1
                        readonly property bool isToday: day === root.todayDay
                            && root.displayMonth === root.todayMonth
                            && root.displayYear === root.todayYear

                        width: (calCol.width - Theme.spacingLg) / 7
                        height: 24
                        radius: Theme.radiusSm
                        color: isToday ? Theme.withAlpha(Theme.primary, 0.18)
                             : (dayMa.containsMouse ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: day.toString()
                            color: isToday ? Theme.primary : Theme.surfaceTextVariant
                            font.family: Theme.fontFamily
                            font.pointSize: Theme.labelLarge
                            font.bold: isToday
                        }

                        MouseArea { id: dayMa; anchors.fill: parent; hoverEnabled: true }
                    }
                }
            }
        }
    }
}
