local function send_shortcut_once(mods, key)
  hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
  end, { timeout = 50, type = "oneshot" })
end

local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end

  return false
end

o.bind("SUPER + Q", "Close window", hl.dsp.window.close())

hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot", "omarchy-capture-screenshot")

o.bind("SUPER + A", "Universal select all", function()
  if active_window_is_terminal() then
    send_shortcut_once("CTRL SHIFT", "A")
  else
    send_shortcut_once("CTRL", "A")
  end
end)
