import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PopupWindow {
    id: root
    implicitWidth: 280
    implicitHeight: calCol.implicitHeight + 24
    color: "transparent"

    // Current displayed month/year (the page the user is looking at)
    property int displayYear: new Date().getFullYear()
    property int displayMonth: new Date().getMonth() 

    // The actual "Real World" date constants
    property int todayDay: new Date().getDate()
    property int todayMonth: new Date().getMonth()
    property int todayYear: new Date().getFullYear()

    readonly property var monthNames: ["January","February","March","April","May","June",
                                       "July","August","September","October","November","December"]
    readonly property var dayNames: ["Su","Mo","Tu","We","Th","Fr","Sa"]

    // Function to synchronize variables with the system clock
    function updateToday() {
        const now = new Date();
        root.todayDay = now.getDate();
        root.todayMonth = now.getMonth();
        root.todayYear = now.getFullYear();
    }

    // Update the date whenever the popup is opened
    onVisibleChanged: {
        if (visible) {
            updateToday();
            // Optional: Uncomment the lines below if you want the calendar 
            // to automatically jump back to the current month when opened
            // root.displayMonth = root.todayMonth;
            // root.displayYear = root.todayYear;
        }
    }

    // Timer to update the date automatically if the shell stays open past midnight
    Timer {
        interval: 60000 // Check every minute
        running: true
        repeat: true
        onTriggered: root.updateToday()
    }

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate()
    }
    function firstDayOfMonth(year, month) {
        return new Date(year, month, 1).getDay()  // 0=Sun
    }
    function prevMonth() {
        if (displayMonth === 0) { displayMonth = 11; displayYear-- }
        else displayMonth--
    }
    function nextMonth() {
        if (displayMonth === 11) { displayMonth = 0; displayYear++ }
        else displayMonth++
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: 8
        color: "#f00d1117"
        border.color: "#335bcefa"
        border.width: 1

        ColumnLayout {
            id: calCol
            anchors { fill: parent; margins: 12 }
            spacing: 8

            // Month navigation header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "‹"
                    color: "#0df0ff"
                    font.pointSize: 12
                    font.bold: true
                    MouseArea { 
                        anchors.fill: parent
                        onClicked: root.prevMonth() 
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.monthNames[root.displayMonth] + "  " + root.displayYear
                    color: "#d8e0f0"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pointSize: 9
                    font.bold: true
                }

                Text {
                    text: "›"
                    color: "#0df0ff"
                    font.pointSize: 12
                    font.bold: true
                    MouseArea { 
                        anchors.fill: parent
                        onClicked: root.nextMonth() 
                    }
                }
            }

            // Day name headers
            Grid {
                columns: 7
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: root.dayNames
                    delegate: Text {
                        required property string modelData
                        width: (calCol.width - 12) / 7
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: "#555e7a"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pointSize: 7
                        font.bold: true
                    }
                }

                // Empty cells before first day
                Repeater {
                    model: root.firstDayOfMonth(root.displayYear, root.displayMonth)
                    delegate: Item {
                        width: (calCol.width - 12) / 7
                        height: 22
                    }
                }

                // Day cells
                Repeater {
                    model: root.daysInMonth(root.displayYear, root.displayMonth)
                    delegate: Rectangle {
                        id: dayRect
                        required property int index
                        readonly property int day: index + 1
                        
                        // This logic is now reactive because root.todayDay is updated by the Timer/Function
                        readonly property bool isToday: day === root.todayDay
                            && root.displayMonth === root.todayMonth
                            && root.displayYear === root.todayYear

                        width: (calCol.width - 12) / 7
                        height: 22
                        radius: 3
                        color: isToday ? "#330df0ff" : (dayMa.containsMouse ? "#1a5bcefa" : "transparent")

                        Rectangle {
                            visible: isToday
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 2 }
                            height: 2
                            radius: 1
                            color: "#0df0ff"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: day.toString()
                            color: isToday ? "#0df0ff" : "#c8d2e0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pointSize: 8
                            font.bold: isToday
                        }

                        MouseArea {
                            id: dayMa
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }
        }
    }
}
