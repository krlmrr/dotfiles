-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({
  output = "desc:Ancor Communications Inc ASUS PB278",
  mode = "preferred",
  position = "0x0",
  scale = omarchy_monitor_scale,
})
hl.monitor({
  output = "desc:ASUSTek COMPUTER INC VG27AQL1A",
  mode = "2560x1440@144.01Hz",
  position = "0x1440",
  scale = omarchy_monitor_scale,
})

for _, hdmi in ipairs({ "HDMI-A-1", "HDMI-A-2" }) do
  hl.monitor({
    output = hdmi,
    mode = "preferred",
    position = "auto",
    scale = 1,
    mirror = "desc:ASUSTek COMPUTER INC VG27AQL1A",
  })
end

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

hl.monitor({ output = "Virtual-1", mode = "2560x1440@60", position = "auto", scale = 1 })

local function is_on_a_monitor(window)
  local center_x = window.at.x + window.size.x / 2
  local center_y = window.at.y + window.size.y / 2
  for _, monitor in ipairs(hl.get_monitors()) do
    local width, height = monitor.width / monitor.scale, monitor.height / monitor.scale
    if (monitor.transform or 0) % 2 == 1 then
      width, height = height, width
    end
    if center_x >= monitor.x and center_x < monitor.x + width and center_y >= monitor.y and center_y < monitor.y + height then
      return true
    end
  end
  return false
end

local function center_stranded_floating_windows()
  for _, window in ipairs(hl.get_windows()) do
    if window.floating and window.mapped and not is_on_a_monitor(window) then
      hl.dispatch(hl.dsp.window.center({ window = "address:" .. window.address }))
    end
  end
end

-- The VG27AQL1A drops off DisplayPort in deep sleep, and Hyprland re-adds it with its floating windows off every screen.
hl.on("monitor.added", function()
  hl.timer(center_stranded_floating_windows, { type = "oneshot", timeout = 1000 })
end)
