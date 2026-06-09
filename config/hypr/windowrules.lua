-- OPACITY
hl.window_rule({ match = { class = "^(Brave-browser)$" }, opacity = "0.98 0.98" })
hl.window_rule({ match = { class = "^(Firefox)$" }, opacity = "0.98 0.98" })
hl.window_rule({ match = { class = "^(librewolf)$" }, opacity = "0.98 0.98" })
hl.window_rule({ match = { class = "^(thunar)$" }, opacity = "0.95 0.95" })

-- Application placement rules
hl.window_rule({ match = { class = "^(Firefox)$" }, workspace = "1 silent" })
hl.window_rule({ match = { class = "^(vesktop)$" }, workspace = "2 silent" })
hl.window_rule({ match = { class = "^(wezterm)$" }, workspace = "3 silent" })
hl.window_rule({ match = { class = "^(wezterm)$" }, workspace = "10 silent" })

-- Layer blur
hl.layer_rule({ match = { namespace = "waybar" }, blur = true })
hl.layer_rule({ match = { namespace = "lockscreen" }, blur = true })
