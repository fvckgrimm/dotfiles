# AGENTS.md — QuickShell Config

This directory contains a **QuickShell** desktop shell configuration written in QML (Qt Modeling Language). QuickShell runs on Wayland compositors (primarily Hyprland) and provides a bar, launcher, notifications, control center, and widgets.

---

## Quick Reference

| Task | Command |
|------|---------|
| **Run/Reload shell** | `qs -c ~/.config/quickshell/shell.qml` |
| **Reload running shell** | `qs ipc call shell reload` (or Super+Shift+R if bound) |
| **IPC calls** | `qs ipc call <target> <function> [args...]` |
| **Test syntax** | `qs -c shell.qml --dry-run` (validates QML) |
| **View logs** | `journalctl -u quickshell -f` (if systemd service) |

---

## Architecture Overview

```
shell.qml (entry point)
├── ShellRoot
│   ├── Process (kill other notif daemons)
│   ├── IpcHandler: "wallpaper" → WallpaperService
│   ├── IpcHandler: "launcher"  → LauncherService
│   ├── IpcHandler: "todo"      → TodoService
│   ├── Variants → Bar (one per screen)
│   ├── Variants → LauncherPopup (one per screen, top-level)
│   └── Variants → TodoWidget  (one per screen, top-level)
```

### Key Components

| File | Purpose |
|------|---------|
| **shell.qml** | Entry point, creates per-screen Bars + top-level popups |
| **Bar.qml** | Main panel (LayerShell Top), hosts widgets, popups anchored to it |
| **Theme.qml** | Singleton: fonts, shapes/spacing/motion tokens, launcher commands, and the **theme system** — 7 palettes (`default`, `catppuccin-mocha/macchiato/frappe/latte`, `dracula`, `rosepine`) keyed by `currentTheme` |
| **SettingsService.qml** | Persistent settings (widget visibility, wallpaper dir, bar layout) → `settings.json` in this repo, symlinked to `~/.config/quickshell/settings.json` |
| **NotificationService.qml** | Notification server, history, DnD, filtering → `~/.local/share/qs-notif-prefs.json` |
| **TodoService.qml** | Day-keyed todo store → `~/.local/share/qs-todos.json` |
| **LauncherService.qml** | Minimal state: open/close, mode (apps/clip/emoji/calc/words) |
| **WallpaperService.qml** | Toggle open/close for WallpaperPicker |
| **Widgets** | `*Widget.qml` — StatChip-based info displays (CPU, Mem, Net, Audio, etc.) |
| **Popups** | `*Popup.qml`, `ControlCenter.qml`, `LauncherPopup.qml` — anchored overlays |
| **StatChip.qml** | Reusable pill: icon + value + optional sparkline, hover/click/right-click |
| **BarButton.qml** | Simple icon button with tooltip, left/right click |

---

## Code Patterns & Conventions

### 1. Singletons for Shared State
```qml
pragma Singleton
import Quickshell
import QtQuick
Scope {
    property bool open: false
    function toggle() { open = !open }
}
```
All services (`SettingsService`, `NotificationService`, `TodoService`, `LauncherService`, `WallpaperService`, `Theme`) use `pragma Singleton` + `Scope`.

### 2. External Process Polling (No Native Bindings)
Most widgets poll system info via `Process` + bash commands:
```qml
Process {
    id: cpuProc
    command: ["bash", "-c", "cat /proc/stat | head -1"]
    running: true
    stdout: SplitParser {
        onRead: data => { /* parse, update properties */ }
    }
}
Timer { interval: 1000; repeat: true; onTriggered: cpuProc.running = true }
```
**Pattern**: `Process` runs once; `Timer` restarts it periodically. `SplitParser` handles stdout line-by-line or whole.

### 3. Persistence via JSON Files
```qml
function _save() {
    saveProc.running = false
    var json = JSON.stringify(root.todos)
    saveProc.command = ["bash", "-c", "mkdir -p ~/.local/share && printf '%s' " +
        JSON.stringify(json).replace(/'/g, "'\\''") + " > ~/.local/share/qs-todos.json"]
    saveProc.running = true
}
```
- Uses `Process` with `printf` + escaped JSON
- `JSON.stringify(json).replace(/'/g, "'\\''")` handles shell escaping
- Load on startup: `cat file 2>/dev/null || echo '{}'`

### 4. Reactive UI with Computed Properties
```qml
readonly property int pendingToday: {
    var list = root.todos[today] ?? []
    return list.filter(t => !t.done).length
}
```
Computed `readonly property` with block syntax `{ ... }` auto-updates when dependencies change.

### 5. Widget Structure (StatChip Pattern)
```qml
Item {
    implicitHeight: 22
    implicitWidth: chip.implicitWidth
    property int usage: 0
    // ... polling logic ...
    RowLayout {
        StatChip {
            id: chip
            icon: "\u{f4bc}"
            value: root.usage + "%"
            iconColor: "#ff656a"
            onClicked: Quickshell.execDetached(["alacritty", "-e", "btop"])
        }
    }
}
```
- Widgets are `Item` with `implicitWidth/Height` bound to internal `StatChip`
- `StatChip` handles hover, click, right-click, tooltip, accent line
- Colors from `Theme` singleton

### 6. IPC Handlers (External Control)
```qml
IpcHandler {
    target: "launcher"
    function show()      { LauncherService.show() }
    function toggle()    { LauncherService.toggle() }
    function apps()      { LauncherService.showMode("apps") }
}
```
Call via: `qs ipc call launcher toggle`

### 7. PanelWindow / PopupWindow (Wayland Layer Shell)
```qml
PanelWindow {                    // Bar
    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top
    exclusiveZone: implicitHeight
}

PopupWindow {                    // ControlCenter, CalendarPopup, etc.
    anchor.window: bar
    anchor.rect.x: bar.width - implicitWidth - 12
    anchor.rect.y: bar.implicitHeight
}
```
- `PanelWindow` = bar/dock (reserves space via `exclusiveZone`)
- `PopupWindow` = transient overlay anchored to a window

### 8. Nerd Font Icons
All icons use Unicode codepoints from Nerd Fonts (e.g., `\u{f0349}`, `\udb80\udd00`). Font set in `Theme.fontFamily`.

---

## Important Gotchas

1. **No build step** — QML is interpreted. Syntax errors only appear at runtime (or with `--dry-run`).

2. **Process escaping** — The `JSON.stringify(json).replace(/'/g, "'\\''")` pattern is critical for saving JSON via bash. Don't simplify it.

3. **Singleton scope** — Services are singletons. Don't instantiate them; import and use directly (`SettingsService.showCpu = false`).

4. **Property binding vs assignment** — Use `root.todos = copy` (triggers binding update) not `root.todos[d] = list` (won't notify).

5. **Timer cleanup** — Timers with `running: true` run forever. Stop them in `onVisibleChanged` if widget/popup hides.

6. **Hyprland-specific** — Uses `Hyprland.dispatch()` for plugins (hyprcapture). Won't work on other compositors.

7. **External dependencies** — Widgets call external tools:
   - `pamixer` / `wpctl` / `amixer` (audio)
   - `brightnessctl` (brightness)
   - `btop`, `pavucontrol`, `alacritty`, `fuzzel`, `nwg-drawer`, `wlogout`
   - `curl` + `wttr.in` (weather)
   - `Hyprland` CLI (workspaces, screenshot plugin)

8. **Settings load order** — `SettingsService` loads `settings.json` async. Widgets default to `true`; config overrides after load. `loadedFromConfig` flag prevents overwriting defaults on first save.

9. **Bar layout is config-driven** — `Bar.qml` renders every module via a catalog of `Component`s selected by `compFor(key)` in three `Repeater`s bound to `SettingsService.barLayout` (`left`/`center`/`right` arrays of keys from `barModuleCatalog`). Reorder/visibility edits happen in `BarLayoutEditor.qml` (drag chips, click to toggle) and persist through `SettingsService.moveBarModule`/`toggleModuleVisible`.

10. **Hidden modules must hide the delegate, not just the widget** — `visible: false` on a widget inside a `Loader` leaves the `Loader`/delegate wrapper visible in the `RowLayout`, reserving a slot and causing gaps. Bind the delegate's `visible` to `SettingsService.isModuleVisible(modelData)`.

11. **Variants for per-screen** — `Variants { model: Quickshell.screens; Bar { screen: modelData } }` creates one Bar per monitor.

12. **LayerShell namespace** — Must be unique per window type (`quickshell:bar`, `quickshell:launcher`, etc.).

13. **Repeater delegates** — This Quickshell build does not pass `modelData`/`index` context properties to delegates whose root is a custom `.qml` type (only to built-in types like `Item`/`Rectangle`). Wrap custom-component delegates in an inline `Item { required property var modelData; required property int index; ... }` and forward them explicitly.

14. **IPC function args must be explicitly typed** — `IpcHandler` rejects untyped parameters (`function set(name)` → "Type of argument 1 cannot be used across IPC" because it infers QVariant). Declare `function set(name: string)` (or `int`/`real`/`bool`/`color`). See `theme` handler in `shell.qml`.

15. **Theme switching is reactive** — `Theme` color tokens are readonly bindings into the active palette (`_p`), so setting `Theme.currentTheme` (via `SettingsService.theme` → `onThemeChanged`) repaints every widget live, no reload. `SettingsService.theme` persists to settings.json. Add a new theme by inserting a full 33-key palette into `Theme.palettes` (the `default` entry is the original and must stay bit-for-bit identical).

---

## Adding a New Widget

1. Create `NewWidget.qml` following `CpuWidget.qml` pattern
2. Add to `Theme.qml` if it needs toggle: `property bool showNewWidget: true`
3. Add to `SettingsService.qml`: property + load/save + `onShowNewWidgetChanged: save()`
4. Register in `Bar.qml`: add a `Component` for the widget, add its key to `compFor(key)`, and insert the key into `SettingsService.barLayout`'s `left`/`center`/`right` default (or add it to `barModuleCatalog` + defaults via `BarLayoutEditor`).
5. Add IPC handler in `shell.qml` if needs external control

---

## Debugging Tips

- **Console output**: `console.log("message")` appears in `journalctl -u quickshell -f` or terminal running `qs`
- **Live reload**: Edit QML → `qs ipc call shell reload` (or bind a key)
- **Inspect properties**: Add temporary `Text { text: JSON.stringify(MyService.property) }` in a widget
- **Process debugging**: Run the bash command manually to verify output format

---

## File Ownership Map

| Area | Files |
|------|-------|
| Entry/IPC | `shell.qml` |
| Bar & Layout | `Bar.qml`, `BarButton.qml`, `StatChip.qml`, `SliderBar.qml`, `BarLayoutEditor.qml`, `BarLayoutSection.qml`, `BarModuleChip.qml` |
| Theme/Config | `Theme.qml`, `SettingsService.qml`, `ThemePicker.qml` |
| Notifications | `NotificationService.qml`, `NotificationCenter.qml`, `NotificationPopup.qml`, `NotifCard.qml` |
| Launcher | `LauncherService.qml`, `LauncherPopup.qml` |
| Todo | `TodoService.qml`, `TodoWidget.qml`, `TodoRow.qml`, `TimeSpinner.qml` |
| Wallpaper | `WallpaperService.qml`, `WallpaperPicker.qml` |
| Control Center | `ControlCenter.qml` |
| Widgets | `AudioWidget`, `BatteryWidget`, `ClockWidget`, `CpuWidget`, `MemoryWidget`, `NetworkWidget`, `StorageWidget`, `TempWidget`, `WeatherWidget`, `WorkspacesWidget`, `MediaWidget`, `TrayWidget`, `CalendarPopup.qml` |

---

## External Scripts Referenced

| Script | Purpose | Called From |
|--------|---------|-------------|
| `~/.scripts/volume` | Volume up/down/mute | `AudioWidget.qml` |
| `fuzzel` | App launcher | `Theme.launcherCmd` |
| `nwg-drawer` | App drawer | `Theme.drawerCmd` |
| `pavucontrol` | Volume mixer | `AudioWidget`, `ControlCenter` |
| `btop` | Process viewer | `CpuWidget`, `MemoryWidget` |
| `alacritty` | Terminal | Various `onClicked` |
| `wlogout` | Power menu | `Bar.qml` |
| `wpctl`/`amixer` | WirePipe/ALSA audio | `AudioWidget`, `ControlCenter` |
| `brightnessctl` | Screen brightness | `ControlCenter` |
| `curl wttr.in` | Weather | `WeatherWidget` |

Ensure these are installed on target system.