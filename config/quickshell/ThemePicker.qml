import Quickshell
import QtQuick
import QtQuick.Layouts

// ThemePicker — clickable chips for the THEME section of settings views.
// Reads Theme.themeNames / Theme.prettyName(), writes SettingsService.theme
// (which persists and applies via onThemeChanged). The active theme chip is
// outlined with Theme.primary and shows a filled accent dot.
Item {
    id: root
    implicitHeight: flow.implicitHeight
    implicitWidth: 220

    Flow {
        id: flow
        anchors.fill: parent
        spacing: Theme.spacingSm

        Repeater {
            model: Theme.themeNames

            delegate: Item {
                required property string modelData

                implicitHeight: 28
                implicitWidth: layout.implicitWidth + Theme.spacingMd * 2

                Rectangle {
                    id: chip
                    anchors.fill: parent
                    radius: Theme.radiusFull
                    color: root.isActive(modelData)
                        ? Theme.withAlpha(Theme.primary, 0.16)
                        : (chipMa.containsMouse ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : Theme.surfaceContainerHigh)
                    border.width: root.isActive(modelData) ? 1 : 0
                    border.color: Theme.primary
                }

                RowLayout {
                    id: layout
                    anchors { fill: parent; leftMargin: Theme.spacingMd; rightMargin: Theme.spacingMd }
                    spacing: Theme.spacingSm

                    // accent dot — uses the theme's own primary so the
                    // palette is recognizable at a glance
                    Rectangle {
                        Layout.preferredWidth: 8
                        Layout.preferredHeight: 8
                        radius: 4
                        color: Theme.palettes[modelData] ? Theme.palettes[modelData].primary : Theme.primary
                    }

                    Text {
                        text: Theme.prettyName(modelData)
                        color: root.isActive(modelData) ? Theme.primary : Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.labelLarge
                        font.bold: root.isActive(modelData)
                    }
                }

                MouseArea {
                    id: chipMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: SettingsService.theme = modelData
                }
            }
        }
    }

    function isActive(name) { return SettingsService.theme === name }
}
