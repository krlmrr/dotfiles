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

hl.unbind("SUPER + W")
hl.unbind("SUPER + T")
hl.unbind("SUPER + F")
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

hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + SHIFT + M", "Apple Music", "omarchy-launch-or-focus-webapp 'chrome-music\\.apple' https://music.apple.com/us/new")

hl.unbind("XF86MonBrightnessUp")
hl.unbind("XF86MonBrightnessDown")
hl.unbind("SHIFT + XF86MonBrightnessUp")
hl.unbind("SHIFT + XF86MonBrightnessDown")
hl.unbind("ALT + XF86MonBrightnessUp")
hl.unbind("ALT + XF86MonBrightnessDown")
o.bind("XF86MonBrightnessUp", "Brightness up", "brightness-all-displays +5%", { locked = true, repeating = true })
o.bind("XF86MonBrightnessDown", "Brightness down", "brightness-all-displays 5%-", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessUp", "Brightness maximum", "brightness-all-displays 100%", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessDown", "Brightness minimum", "brightness-all-displays 1%", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessUp", "Brightness up precise", "brightness-all-displays +1%", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessDown", "Brightness down precise", "brightness-all-displays 1%-", { locked = true, repeating = true })
