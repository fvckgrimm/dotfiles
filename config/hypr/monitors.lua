-- Desktop Setup
hl.monitor({ output = "DP-2", mode = "highrr", position = "auto", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "1080x-630", scale = 1, transform = 1 })

-- Laptop setup
hl.monitor({ output = "eDP-1", mode = "2560x1600@60", position = "0x0", scale = 2 })
-- If your laptop uses DP-2 differently than your desktop, be careful with naming conflicts!
hl.monitor({ output = "DP-2", mode = "1920x1080@74.97", position = "1280x0", scale = 1 })
