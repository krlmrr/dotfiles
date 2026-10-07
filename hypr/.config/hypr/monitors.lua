-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "desc:Ancor Communications Inc ASUS PB278", mode = "preferred", position = "0x0", scale = omarchy_monitor_scale })
hl.monitor({ output = "desc:ASUSTek COMPUTER INC VG27AQL1A", mode = "2560x1440@144.01Hz", position = "0x1440", scale = omarchy_monitor_scale })

hl.workspace_rule({ workspace = "1", monitor = "desc:ASUSTek COMPUTER INC VG27AQL1A", default = true })
hl.workspace_rule({ workspace = "2", monitor = "desc:Ancor Communications Inc ASUS PB278", default = true })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

hl.monitor({ output = "Virtual-1", mode = "2560x1440@60", position = "auto", scale = 1 })
