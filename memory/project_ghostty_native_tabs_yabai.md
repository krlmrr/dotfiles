---
name: project_ghostty_native_tabs_yabai
description: Ghostty tabs on macOS are native NSWindow tabs, so yabai tiles each tab as its own window; cmd+t is unbound to prevent it
metadata:
  type: project
---

On macOS, Ghostty tabs are AppKit **native NSWindow tabs** — every tab is a real
window. Verified 2026-08-18 on space 5 (unmanaged, so raw yabai BSP, not the
yabairc placement logic):

- each `cmd+t` fires a yabai `window_created` with a fresh id (`/tmp/yabai.log`:
  `place-one: 47555 … 47566 … 47578`)
- each reports `role=AXWindow`, `subrole=AXStandardWindow`, `is-floating=false` —
  **indistinguishable from a genuine second window**, so no yabai rule can single
  them out (a rule would have to unmanage every Ghostty window)
- the tile halved the instant the tab appeared: `1583x1747` → `1583x868`, the
  other half held by the non-selected tab

`ghostty +show-config --default` exposes no knob to make tabs non-native.

**Fix in place:** `keybind = cmd+t=unbind` in `ghostty/config`. Ghostty builds
its macOS menu from the keybind table, so this also strips File ▸ New Tab's
shortcut. Use splits or `cmd+n` instead.
(Was the mac branch of `shared/ghostty/build.sh` until v2.0.0 flattened the repo;
that build script and `./buildghostty` are gone — the config is symlinked to both
`~/.config/ghostty/config` and the app-support path, so edits are live.) See
[[project_yabai_ax_loss]] for the separate phantom-window issue that shows up in
the same queries (app name lowercased to `ghostty`, empty role/subrole,
`--window <id>` cannot find them).
