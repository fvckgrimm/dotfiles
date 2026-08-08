local scriptsDir = os.getenv("HOME") .. "/.config/hypr/scripts"
local notifycmd = "notify-send -h string:x-canonical-private-synchronous:hypr-cfg -u low"

local volume = scriptsDir .. "/volume"
local file = "thunar"
local screenshot = scriptsDir .. "/screensht"
local colorpicker = scriptsDir .. "/colorpicker"
local powermenu = scriptsDir .. "/powermenu"
local connect = "oneplush-connect"

-- --- NATIVE SCREENSHOTS (HyprCapture) --- --
-- Pressing just Super+Shift+S opens the interactive "fusion" overlay
hl.bind("SUPER + SHIFT + S", function()
	hl.plugin.hyprcapture.open()
end)

-- Direct modes (skips the mode selector)
hl.bind("Print", function()
	hl.plugin.hyprcapture.open("fullscreen")
end)

hl.bind("CTRL + Print", function()
	hl.plugin.hyprcapture.open("region")
end)

hl.bind("ALT + Print", function()
	hl.plugin.hyprcapture.open("window")
end)

-- MISC
hl.bind("SUPER + ALT + L", hl.dsp.exec_cmd("wlogout"))
hl.bind("SUPER + T", hl.dsp.exec_cmd("nautilus"))
--hl.bind("SUPER + T", hl.dsp.exec_cmd("thunar"))
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
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("qs ipc call theme cycle"))
hl.bind("SUPER + CTRL + T", hl.dsp.exec_cmd("qs ipc call theme set catppuccin-mocha"))
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("qs ipc call launcher pass"))
hl.bind("SUPER + CTRL + S", hl.dsp.exec_cmd("qs ipc call launcher ssh"))
hl.bind("SUPER + CTRL + K", hl.dsp.exec_cmd("qs ipc call launcher kaomoji"))
hl.bind("SUPER + B", hl.dsp.exec_cmd("qs ipc call bar toggle"))

-- --- NATIVE WINDOW MANAGEMENT --- --
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + Q", hl.dsp.exit())
hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + G", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + P", hl.dsp.window.pseudo({ action = "toggle" }))

-- Changing gaps dynamically using Lua functions instead of shell commands!
hl.bind("SUPER + Y", function()
	hl.config({ general = { gaps_in = 0, gaps_out = 0 } })
end)
hl.bind("SUPER + U", function()
	hl.config({ general = { gaps_in = 4, gaps_out = 10 } })
end)

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

-- --- NATIVE WORKSPACE NAVIGATION --- --
for i = 1, 9 do
	local key = tostring(i)
	-- Switch to workspace
	hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = key }))
	-- Move window to workspace and switch to it
	hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = key, follow = true }))
	-- Move window to workspace silently (do not follow)
	hl.bind("SUPER + CTRL + SHIFT + " .. key, hl.dsp.window.move({ workspace = key, follow = false }))
end

-- Keybinds for workspace 10 (mapped to 0)
hl.bind("SUPER + 0", hl.dsp.focus({ workspace = "10" }))
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = "10", follow = true }))
hl.bind("SUPER + CTRL + SHIFT + 0", hl.dsp.window.move({ workspace = "10", follow = false }))

-- --- MOUSE BINDINGS --- --
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
-- Scroll workspaces
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e-1" }))

-- RESIZE WINDOWS (Interactive via keyboard)
hl.bind("SUPER + A", hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
hl.bind("SUPER + S", hl.dsp.window.resize({ x = 0, y = 20, relative = true }))
hl.bind("SUPER + W", hl.dsp.window.resize({ x = 0, y = -20, relative = true }))
hl.bind("SUPER + D", hl.dsp.window.resize({ x = 20, y = 0, relative = true }))

-- --- SCROLLING LAYOUT SPECIFIC BINDS (NIRI STYLE) --- --

-- Consume or Expel (Mod + BracketLeft / BracketRight)
hl.bind("SUPER + bracketleft", hl.dsp.layout("consume_or_expel prev"))
hl.bind("SUPER + bracketright", hl.dsp.layout("consume_or_expel next"))

-- Cycle Preset Column Widths (Mod + R)
hl.bind("SUPER + R", hl.dsp.layout("colresize +conf"))

-- Fine width adjustments (Mod + Minus / Mod + Equal)
hl.bind("SUPER + minus", hl.dsp.layout("colresize -0.1"))
hl.bind("SUPER + equal", hl.dsp.layout("colresize +0.1"))

-- Maximize Column (Mod + F) vs True Fullscreen (Mod + Shift + F)
hl.bind("SUPER + F", hl.dsp.layout("fit expand"))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen())

-- Center Column (Mod + C)
hl.bind("SUPER + C", hl.dsp.layout("fit active"))

-- Move columns manually across the scroll space
hl.bind("SUPER + SHIFT + bracketleft", hl.dsp.layout("swapcol l"))
hl.bind("SUPER + SHIFT + bracketright", hl.dsp.layout("swapcol r"))
