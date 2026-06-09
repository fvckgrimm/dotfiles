local scriptsDir = os.getenv("HOME") .. "/.config/hypr/scripts"
local notifycmd = "notify-send -h string:x-canonical-private-synchronous:hypr-cfg -u low"

local volume = scriptsDir .. "/volume"
local file = "thunar"
local screenshot = scriptsDir .. "/screensht"
local colorpicker = scriptsDir .. "/colorpicker"
local powermenu = scriptsDir .. "/powermenu"
local connect = "oneplush-connect"

-- SCREENSHOT SHIT
hl.bind("Print", hl.dsp.exec_cmd(screenshot .. " screen"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd(screenshot .. " area"))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("wl-paste | swappy -f -"))

-- MISC
hl.bind("SUPER + ALT + L", hl.dsp.exec_cmd("wlogout"))
hl.bind("SUPER + T", hl.dsp.exec_cmd("thunar"))
hl.bind("SUPER + return", hl.dsp.exec_cmd("wezterm"))
hl.bind("SUPER + SHIFT + X", hl.dsp.exec_cmd(colorpicker))
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd("jerry"))

-- QUICKSHELL BINDING
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"))
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("qs ipc call launcher apps"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("qs ipc call launcher clip"))
hl.bind("SUPER + CTRL + W", hl.dsp.exec_cmd("qs ipc call launcher words"))
hl.bind("SUPER + period", hl.dsp.exec_cmd("qs ipc call launcher emoji"))
hl.bind("SUPER + BACKSLASH", hl.dsp.exec_cmd("qs ipc call launcher calc"))
hl.bind("SUPER + N", hl.dsp.exec_cmd("qs ipc call todo toggle"))

-- WINDOW MANAGEMENT
hl.bind("SUPER + Q", hl.dsp.exec_cmd("hyprctl dispatch killactive"))
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("hyprctl dispatch exit"))
hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + G", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + P", hl.dsp.window.pseudo())
hl.bind("SUPER + Y", hl.dsp.exec_cmd("hyprctl keyword general:gaps_in 0 && hyprctl keyword general:gaps_out 0"))
hl.bind("SUPER + U", hl.dsp.exec_cmd("hyprctl keyword general:gaps_in 4 && hyprctl keyword general:gaps_out 10"))

-- Change Workspace Mode
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allfloat"))
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd(notifycmd .. " 'Toggled All Float Mode'"))
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allpseudo"))
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd(notifycmd .. " 'Toggled All Pseudo Mode'"))

-- alternative focus binds
hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }))

-- alternative move binds
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "u" }))

-- SWITCH WORKSPACE & MOVE TO WORKSPACE
-- We can dynamically generate keys 1 through 9 using a lua loop!
for i = 1, 9 do
	local key = tostring(i)
	hl.bind("SUPER + " .. key, hl.dsp.exec_cmd("hyprctl dispatch workspace " .. key))
	hl.bind("SUPER + SHIFT + " .. key, hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace " .. key))
	hl.bind("SUPER + CTRL + SHIFT + " .. key, hl.dsp.exec_cmd("hyprctl dispatch movetoworkspacesilent " .. key))
end

-- Keybinds for 0
hl.bind("SUPER + 0", hl.dsp.exec_cmd("hyprctl dispatch workspace 10"))
hl.bind("SUPER + SHIFT + 0", hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace 10"))
hl.bind("SUPER + CTRL + SHIFT + 0", hl.dsp.exec_cmd("hyprctl dispatch movetoworkspacesilent 10"))

-- RESIZE WINDOWS
hl.bind("SUPER + A", hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
hl.bind("SUPER + S", hl.dsp.window.resize({ x = 0, y = 20, relative = true }))
hl.bind("SUPER + W", hl.dsp.window.resize({ x = 0, y = -20, relative = true }))
hl.bind("SUPER + D", hl.dsp.window.resize({ x = 20, y = 0, relative = true }))

-- MOUSE BINDINGS
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + mouse_up", hl.dsp.exec_cmd("hyprctl dispatch workspace e+1"))
hl.bind("SUPER + mouse_down", hl.dsp.exec_cmd("hyprctl dispatch workspace e-1"))

-- --- SCROLLING LAYOUT SPECIFIC BINDS (NIRI STYLE) --- --
-- Consume or Expel (Mod + BracketLeft / BracketRight)
-- If alone in a column, it consumes the adjacent window. If with other windows, it expels it to a new column.
hl.bind("SUPER + bracketleft", hl.dsp.layout("consume_or_expel prev"))
hl.bind("SUPER + bracketright", hl.dsp.layout("consume_or_expel next"))
-- Cycle Preset Column Widths (Mod + R)
-- This cycles through the `explicit_column_widths` defined in hyprland.lua
hl.bind("SUPER + R", hl.dsp.layout("colresize +conf"))
-- Fine width adjustments (Mod + Minus / Mod + Equal)
-- Increases or decreases column width by 10%
hl.bind("SUPER + minus", hl.dsp.layout("colresize -0.1"))
hl.bind("SUPER + equal", hl.dsp.layout("colresize +0.1"))
-- Maximize Column (Mod + F) vs True Fullscreen (Mod + Shift + F)
-- Niri `maximize-column` expands the column to take the screen without hiding the bar.
hl.bind("SUPER + F", hl.dsp.layout("fit expand"))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen())
-- Center Column (Mod + C)
-- Forces the current active column to perfectly fit/center on your screen
hl.bind("SUPER + C", hl.dsp.layout("fit active"))
-- Move columns manually across the scroll space
hl.bind("SUPER + SHIFT + bracketleft", hl.dsp.layout("swapcol l"))
hl.bind("SUPER + SHIFT + bracketright", hl.dsp.layout("swapcol r"))
