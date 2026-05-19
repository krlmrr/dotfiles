---
name: Yabai display event semantics
description: display_changed fires on focus crossing screens; for hardware reconfig use display_added/removed/moved/resized
type: feedback
originSessionId: f5ed4a99-0fc7-47d7-be3b-7340788938d5
---
In yabai signals, `display_changed` fires whenever the **active display** changes — i.e., focus or cursor crosses to another screen during normal multi-monitor use. It is **not** a hardware-reconfiguration event.

For actual display hardware/arrangement changes (the usual intent), bind to the specific events:
- `display_added` — monitor plugged in
- `display_removed` — monitor unplugged
- `display_resized` — resolution change
- `display_moved` — arrangement change

**Why:** A `display_changed` → `yabai --restart-service` signal in `mac/yabai/yabairc` caused yabai to restart every time the cursor crossed between screens. Each restart rebuilt the BSP tree before yabairc could re-apply `layout=float` to space 2, leaving chat apps (Slack/Discord/Messages/Teams) BSP-managed instead of floating. Symptom: "yabai is managing windows for no reason."

**How to apply:** Never bind expensive/destructive actions (`--restart-service`, full re-tile, rule re-apply) to `display_changed`. If you mean "when the display config changes," enumerate the four specific events above. Also: any action that does `yabai --restart-service` should be paired with explicit recovery of per-space float layouts (changing space layout to float does not retroactively float windows already in the BSP tree).
