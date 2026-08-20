---
name: project-yabai-pip-masquerade
description: Zen Picture-in-Picture reports subrole AXStandardWindow — must be excluded by title in win_id/external_correct/move or it hijacks editor placement
metadata:
  type: project
---

Zen's **Picture-in-Picture** popout window reports `subrole == "AXStandardWindow"` — identical to a real browser window — so any `select(.app=="Zen" and .subrole=="AXStandardWindow")` in `yabai/yabairc` can grab it instead of the real browser. It's kept floating by the `title="^Picture-in-Picture$" manage=off` rule and is `is-sticky: true` (that's why it shows on ALL desktops — native PiP behavior, NOT a bug, NOT caused by the script).

## The bug it caused (debugged 2026-07-02)

Two symptoms, one cause. Whenever PiP was open, `win_id Zen` returned the PiP window (floating, unmanaged). In `place_editors`:
- **Random red box**: the float/reinsert rebuild ran `yabai -m window <zed> --insert west` (draws yabai's insert-feedback overlay, default color `0xffd75f5f` — a dusty red), then `ensure_tiled <zen>` was supposed to re-tile the floated Zen to consume the insertion point. But `<zen>` was the PiP window (manage=off/floating) → the re-tile no-op'd → the insertion point was never consumed → **the red overlay lingered**. Triggered by the `window_created app="^Zen$"` signal firing when PiP opened. "Only when PiP is up, only occasionally."
- **Wrong layout**: `place_editors` arranged the PiP window into the editor stack and never positioned the real browser.

## Fix (implemented in yabai/yabairc)

Exclude PiP by title (`and .title != "Picture-in-Picture"`) in the three spots that hunt for the real Zen window: `win_id()`, `external_correct()`'s `$w` filter, and `move()`. PiP keeps floating via its own rule; the drag drop-indicator (same insert-feedback overlay, used intentionally on alt-drag via `mouse_action1 move`) stays intact because the color is untouched.

## Gotchas for future work
- yabai's `--insert` has **no cancel/none** — the only clear is re-issuing the SAME direction (a toggle), and the insertion-point state is **not exposed** in `yabai -m query --windows` (only `split-type`/`split-child`/`stack-index`). So there is no clean "clear the overlay at the end" one-liner; fix the consume path instead.
- Don't disable `insert_feedback_color` to kill the box — Karl uses that overlay as the drop-target indicator when alt-dragging windows.
- PiP `is-sticky: true` = on all desktops by design. To pin it to one space instead, add a `sticky=off` rule for the PiP title.

See [[project-yabai-wake-no-restart]], [[feedback-yabai-space2]], [[feedback-yabai-display-events]].
