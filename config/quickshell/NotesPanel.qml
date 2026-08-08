import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// NotesPanel — full-height side panel for the notes system. Same overlay
// pattern as TodoWidget/LauncherPopup, but the card hugs the right edge at
// full screen height. Left column = note list (Scratchpad pinned first, then
// pinned notes, then the rest). Right = editor with rename-in-header, pin,
// inline delete confirm, and a markdown preview toggle.
PanelWindow {
    id: root

    required property var barWindow
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell:notes"
    exclusiveZone: 0
    anchors {}

    implicitWidth:  screen.width
    implicitHeight: screen.height
    color: "transparent"
    screen: barWindow ? barWindow.screen : undefined

    property bool   preview: false       // markdown preview vs edit
    property bool   renaming: false      // rename field open in header
    property string renameText: ""
    property string confirmDel: ""       // note name awaiting delete confirmation

    readonly property bool isScratch: NotesService.currentName === NotesService.scratchName
    readonly property bool dirty: NotesService.currentContent !== NotesService.savedContent

    // Notes sorted for the sidebar: Scratchpad, pinned (alpha), rest (alpha).
    // Scratchpad is rendered as the first entry regardless of NotesService list.
    readonly property var listModel: {
        var out = []
        out.push({ name: NotesService.scratchName, pinned: true, isScratch: true })
        var pinned = [], rest = []
        for (var i = 0; i < NotesService.notes.length; i++) {
            var n = NotesService.notes[i]
            if (n.name === NotesService.scratchName) continue
            if (n.pinned) pinned.push(n)
            else rest.push(n)
        }
        pinned.sort((a, b) => a.name.localeCompare(b.name))
        rest.sort((a, b) => a.name.localeCompare(b.name))
        for (var j = 0; j < pinned.length; j++) out.push({ name: pinned[j].name, pinned: true, isScratch: false })
        for (var k = 0; k < rest.length; k++) out.push({ name: rest[k].name, pinned: false, isScratch: false })
        return out
    }

    function open() {
        NotesService.refresh()
        if (NotesService.currentName === "") {
            // Restore the last opened note, else land on the scratchpad.
            var target = (NotesService.last !== "" && NotesService.noteExists(NotesService.last))
                ? NotesService.last : NotesService.scratchName
            NotesService.openNote(target)
        }
        visible = true
        Qt.callLater(() => { if (root.preview) previewText.forceActiveFocus(); else editor.forceActiveFocus() })
    }

    function close() { visible = false; NotesService.open = false }

    function applyRename() {
        var newName = root.renameText.trim()
        if (newName !== "" && newName !== NotesService.currentName) {
            NotesService.renameNote(NotesService.currentName, newName)
        }
        root.renaming = false
    }

    // Inline delete confirmation: first click arms, second click deletes.
    function tryDelete() {
        if (root.confirmDel === NotesService.currentName) {
            NotesService.deleteCurrent()
            root.confirmDel = ""
        } else {
            root.confirmDel = NotesService.currentName
            deleteReset.restart()
        }
    }

    Timer {
        id: deleteReset
        interval: 2500
        onTriggered: root.confirmDel = ""
    }

    property bool _ready: false
    Component.onCompleted: Qt.callLater(() => { _ready = true })

    Connections {
        target: NotesService
        function onOpenChanged() {
            if (!root._ready) return
            if (NotesService.open) root.open()
            else if (root.visible) root.close()
        }
        function onCurrentNameChanged() {
            if (root._ready && root.visible) {
                root.renaming = false
                root.renameText = NotesService.currentName
                root.preview = false
            }
        }
    }

    // Autosave on close, plus wipe transient UI state.
    onVisibleChanged: {
        if (!_ready) return
        if (!visible) {
            NotesService.open = false
            root.confirmDel = ""
            root.renaming = false
            if (NotesService.currentName !== "" && NotesService.currentContent !== NotesService.savedContent) {
                NotesService.saveCurrent()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.withAlpha("#000000", 0.5)

        MouseArea { anchors.fill: parent; onClicked: root.close() }

        Rectangle {
            id: panel
            anchors { top: parent.top; right: parent.right; bottom: parent.bottom; margins: Theme.spacingMd }
            width: 900
            radius: Theme.radiusXl
            color: Theme.cardColor()
            border.color: Theme.cardBorder()
            border.width: 1

            MouseArea { anchors.fill: parent; onClicked: {} }

            ColumnLayout {
                anchors { fill: parent; margins: Theme.spacingXl }
                spacing: Theme.spacingMd

                // ── Header ──────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSm

                    Text {
                        text: SettingsService.notesGlyph
                        color: Theme.primary
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.bodyLarge
                        font.bold: true
                    }
                    Text {
                        text: "Notes"
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.bodyLarge
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: NotesService.currentName !== ""
                            ? (root.dirty ? "●" : "✓")
                            : ""
                        color: root.dirty ? Theme.warning : Theme.secondary
                        font.pointSize: Theme.labelLarge
                        ToolTip.visible: root.dirty
                        ToolTip.text: "unsaved"
                    }

                    Rectangle {
                        implicitWidth: 26; implicitHeight: 26; radius: Theme.radiusSm
                        color: newMa.containsMouse ? Theme.withAlpha(Theme.primary, 0.16) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color: Theme.primary
                            font.family: Theme.fontFamily; font.pointSize: Theme.titleMedium; font.bold: true
                        }
                        MouseArea {
                            id: newMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                root.confirmDel = ""
                                NotesService.createNote(NotesService.timestampName(), "")
                            }
                        }
                    }
                    Rectangle {
                        implicitWidth: 26; implicitHeight: 26; radius: Theme.radiusSm
                        visible: NotesService.currentName !== ""
                        color: pinMa.containsMouse ? Theme.withAlpha(Theme.secondary, 0.16) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: NotesService.isPinned(NotesService.currentName) ? "\u{f08d}" : "\u{f08d}"
                            color: NotesService.isPinned(NotesService.currentName) ? Theme.secondary : Theme.surfaceTextVariant
                            font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                        }
                        MouseArea {
                            id: pinMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: NotesService.togglePinCurrent()
                        }
                    }
                    Rectangle {
                        implicitWidth: 26; implicitHeight: 26; radius: Theme.radiusSm
                        visible: NotesService.currentName !== ""
                        color: previewMa.containsMouse ? Theme.withAlpha(Theme.primary, 0.16) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "\u{f0f6}"
                            color: root.preview ? Theme.primary : Theme.surfaceTextVariant
                            font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                        }
                        MouseArea {
                            id: previewMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                root.preview = !root.preview
                                if (root.preview) Qt.callLater(() => previewText.forceActiveFocus())
                                else Qt.callLater(() => editor.forceActiveFocus())
                            }
                        }
                    }
                    Rectangle {
                        implicitWidth: 26; implicitHeight: 26; radius: Theme.radiusSm
                        visible: NotesService.currentName !== ""
                        color: delMa.containsMouse || root.confirmDel !== "" ? Theme.withAlpha(Theme.error, 0.18) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: root.confirmDel === NotesService.currentName ? "\u{f00c}" : "\u{f1f8}"
                            color: (delMa.containsMouse || root.confirmDel !== "") ? Theme.error : Theme.surfaceTextVariant
                            font.family: Theme.fontFamily; font.pointSize: Theme.labelLarge
                        }
                        MouseArea {
                            id: delMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: root.tryDelete()
                        }
                    }
                    Text {
                        text: "✕"; color: Theme.surfaceTextVariant; font.pointSize: Theme.titleSmall
                        MouseArea { anchors.fill: parent; onClicked: root.close() }
                    }
                }

                // ── Split: list + editor ───────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.spacingLg

                    // Sidebar
                    Rectangle {
                        Layout.preferredWidth: 220
                        Layout.fillHeight: true
                        radius: Theme.radiusMd
                        color: Theme.surfaceContainerLow

                        ListView {
                            id: noteList
                            anchors.fill: parent
                            anchors.margins: Theme.spacingXs
                            clip: true
                            spacing: Theme.spacingXs
                            model: root.listModel
                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                parent: noteList
                                anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
                            }

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool active: NotesService.currentName === modelData.name
                                width: noteList.width - Theme.spacingXs
                                height: 30
                                radius: Theme.radiusSm
                                color: active ? Theme.withAlpha(Theme.primary, 0.16)
                                    : (listMa.containsMouse ? Theme.withAlpha(Theme.surfaceText, Theme.stateHoverOpacity) : "transparent")

                                RowLayout {
                                    anchors { fill: parent; leftMargin: Theme.spacingSm; rightMargin: Theme.spacingSm }
                                    spacing: Theme.spacingSm

                                    Text {
                                        visible: modelData.pinned
                                        text: "\u{f08d}"
                                        color: Theme.secondary
                                        font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: active ? Theme.primary : Theme.surfaceTextVariant
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.labelLarge
                                        font.bold: active || modelData.isScratch
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: listMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        root.confirmDel = ""
                                        if (NotesService.currentName !== modelData.name) NotesService.openNote(modelData.name)
                                    }
                                }
                            }
                        }
                    }

                    // Editor
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.radiusMd
                        color: Theme.surfaceContainerLow

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingMd
                            spacing: Theme.spacingSm

                            // Rename-in-header (Enter applies, like Noctalia)
                            Item {
                                Layout.fillWidth: true
                                implicitHeight: renameInput.implicitHeight + Theme.spacingXs

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: NotesService.currentName !== ""
                                        ? (NotesService.currentName + "." + SettingsService.notesExtension)
                                        : "no note open"
                                    color: NotesService.currentName !== "" ? Theme.surfaceText : Theme.surfaceTextDim
                                    font.family: Theme.fontFamily
                                    font.pointSize: Theme.bodyMedium
                                    font.bold: true
                                    visible: !root.renaming
                                    elide: Text.ElideMiddle
                                    width: parent.width - 90
                                }

                                TextInput {
                                    id: renameInput
                                    anchors { left: parent.left; right: parent.right }
                                    anchors.rightMargin: 60
                                    visible: root.renaming
                                    text: root.renameText
                                    color: Theme.surfaceText
                                    font.family: Theme.fontFamily
                                    font.pointSize: Theme.bodyMedium
                                    font.bold: true
                                    selectByMouse: true
                                    onTextChanged: root.renameText = text

                                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            root.applyRename()
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Escape) {
                                            root.renaming = false
                                            event.accepted = true
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    visible: !root.renaming
                                    hoverEnabled: true
                                    onClicked: {
                                        if (NotesService.currentName === "") return
                                        root.renameText = NotesService.currentName
                                        root.renaming = true
                                        Qt.callLater(() => {
                                            renameInput.forceActiveFocus()
                                            renameInput.selectAll()
                                        })
                                    }
                                }

                                Text {
                                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                    visible: root.renaming
                                    text: "↵ save"
                                    color: Theme.secondary
                                    font.family: Theme.fontFamily; font.pointSize: Theme.labelSmall
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outlineVariant }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: Theme.radiusMd
                                color: Theme.surfaceContainerHigh
                                visible: !root.preview
                                clip: true

                                Flickable {
                                    id: editFlick
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingMd
                                    clip: true
                                    contentWidth: width
                                    contentHeight: editor.implicitHeight

                                    TextEdit {
                                        id: editor
                                        width: editFlick.width
                                        height: Math.max(editFlick.height, implicitHeight)
                                        color: Theme.surfaceText
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.bodyMedium
                                        selectByMouse: true
                                        selectionColor: Theme.withAlpha(Theme.secondary, 0.2)
                                        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                                        text: NotesService.currentContent
                                        onTextChanged: {
                                            if (NotesService.currentContent !== text) NotesService.setContent(text)
                                        }

                                        Keys.onPressed: event => {
                                            if (event.key === Qt.Key_Escape) {
                                                root.close()
                                                event.accepted = true
                                            } else if ((event.modifiers & Qt.ControlModifier)
                                                       && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                                                NotesService.saveCurrent()
                                                event.accepted = true
                                            }
                                        }
                                    }

                                    ScrollBar.vertical: ScrollBar {
                                        policy: ScrollBar.AsNeeded
                                        parent: editFlick
                                        anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
                                    }
                                }
                            }

                            // Markdown preview — read-only render of the same buffer
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: Theme.radiusMd
                                color: Theme.surfaceContainerHigh
                                visible: root.preview
                                clip: true

                                Flickable {
                                    id: previewFlick
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingMd
                                    clip: true
                                    contentWidth: width
                                    contentHeight: previewText.implicitHeight

                                    TextEdit {
                                        id: previewText
                                        width: previewFlick.width
                                        height: Math.max(previewFlick.height, implicitHeight)
                                        readOnly: true
                                        textFormat: TextEdit.MarkdownText
                                        color: Theme.surfaceText
                                        font.family: Theme.fontFamily
                                        font.pointSize: Theme.bodyMedium
                                        selectionColor: Theme.withAlpha(Theme.secondary, 0.2)
                                        selectByMouse: true
                                        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                                        text: NotesService.currentContent
                                        Keys.onPressed: event => {
                                            if (event.key === Qt.Key_Escape) root.close()
                                            event.accepted = true
                                        }
                                    }

                                    ScrollBar.vertical: ScrollBar {
                                        policy: ScrollBar.AsNeeded
                                        parent: previewFlick
                                        anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "type · autosaves  ·  ctrl+enter save  ·  click title to rename  ·  esc close"
                    color: Theme.surfaceTextDim
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.labelSmall
                }
            }
        }
    }
}
