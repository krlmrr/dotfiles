-- Extra autostart processes.
-- o.launch_on_start("my-service")

local primary_monitor = "desc:ASUSTek COMPUTER INC VG27AQL1A"

local function focus_primary_monitor()
  hl.dispatch(hl.dsp.focus({ monitor = primary_monitor }))
end

hl.on("hyprland.start", function()
  focus_primary_monitor()
  hl.timer(focus_primary_monitor, { timeout = 2000, type = "oneshot" })
end)

o.launch_on_start("tuple on")
