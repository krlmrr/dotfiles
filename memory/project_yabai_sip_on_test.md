---
name: project-yabai-sip-on-test
description: Karl is testing yabai WITHOUT SIP disabled on a macOS 27 beta volume; wants a SIP-on yabairc variant
metadata:
  type: project
---

On 2026-06-09 Karl installed the macOS 27 "Golden Gate" Beta 1 (build 26A5353q) onto a separate APFS volume named "Beta" (M2 Max, main install stays on `Macintosh HD`). Goal there: see how much of the yabai setup works **without disabling SIP** — i.e., with no scripting addition (SA) loaded.

If a future session is running in a clone of this repo on that beta volume and Karl wants to make yabai usable there, build a **SIP-on variant of `mac/yabai/yabairc`**: drop `sudo yabai --load-sa` and the `dock_did_restart` reload, and remove/disable everything that needs the SA — `place_editors` (uses `window --space`), the `ctrl - N` / `ctrl+shift - N` / `ctrl+shift+←→` space-move/switch binds in `skhdrc`, and any opacity/shadow/sticky/layer config. Keep all the in-space tiling (bsp, gaps, `manage=off` rules, focus/warp/resize, layout toggles, `space --balance/--mirror`). Lean on macOS-native spaces for switching (`ctrl+←→`, enable `ctrl+number` in System Settings → Keyboard → Mission Control); moving a window across spaces without SA means a Mission Control drag (no clean keybind).

The SA boundary and the main no-restart design are documented in [[project-yabai-wake-no-restart]].
