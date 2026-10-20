-- Written by `oma-cast setup hyprland`. Safe to edit; rerunning setup overwrites it.
-- Alt+Space reaches the plugin's global shortcut directly, so no process
-- starts per keypress. Omarchy's own menu stays on Super+Space.
o.bind("ALT + SPACE", "oma-cast launcher", hl.dsp.global("oma-cast:toggle"))

-- To put oma-cast on Super+Space instead of the Omarchy menu:
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "oma-cast launcher", hl.dsp.global("oma-cast:toggle"))
