---
name: Yabai space 2 is intentionally unmanaged
description: Space 2 (chat) must stay float across all restarts via manage=off rules + rule --apply. Never use --toggle float on float-layout spaces.
type: feedback
---

Space 2 (label `chat`) is configured as `layout float` in `mac/yabai/yabairc` and intentionally hosts chat apps (Slack, Discord, Telegram, Messages, Microsoft Teams, Tuple). It must NEVER appear in yabai window-management fixes, diagnostics, or filters.

## What actually makes space 2 stay floating across restarts

The canonical primitives, per `man yabai`:

1. **Per-app rule with `manage=off`**: this is the documented way to make a window float ("Most windows will be managed automatically, so this should mainly be used to make a window float"). Each chat app has `space=2 manage=off`.
2. **`yabai -m rule --apply` at the end of yabairc**: retroactively applies rules to already-existing windows. Without this, rules only apply to windows created AFTER the rule was added — so after `--restart-service`, pre-existing chat windows wouldn't get the manage=off treatment.

Together these keep windows floating with original positions preserved across `yabai --restart-service`, system_woke, and all display events. **No recovery code, no save/restore, no race-condition workarounds are needed.**

## What NOT to use

**`yabai -m window <id> --toggle float`** — per the man page: *"toggle whether the focused window should be tiled (only on bsp spaces)"*. It is BSP-only and has undefined behavior on float-layout spaces. We spent an evening debugging "managed-looking space 2 after wake" before realizing the recovery code was using a BSP-only command on a float space. It both flipped state in non-obvious ways and moved windows to tile coordinates.

**`yabai -m window <id> --resize abs:w:h` on managed windows** — per the man page: *"cannot be used on managed windows"*. Silently no-ops. Don't use as part of any "restore positions after restart" attempt; if the window is in managed state at that moment, the resize does nothing.

**Save/restore window positions around `--restart-service`** — unnecessary. With manage=off + rule --apply, positions are preserved naturally because windows never enter the BSP tree to begin with.

## How to apply

When working in this repo:
- Filter out space 2 windows in any yabai diagnostic / scripting (e.g., `select(.space != 2)`).
- If asked to fix "yabai is managing chat windows", check that the per-app rules have `manage=off` and that `yabai -m rule --apply` is at the end of yabairc — those are the only two things needed.
- Read `man yabai` before reaching for `--toggle float`, `--resize abs`, or other commands that have layout-specific or state-specific constraints.

## Why this matters

User has had to point out "don't touch space 2" multiple times. The first time was about excluding space 2 from diagnostic output; the second was about a `display_changed` → `--restart-service` signal that broke the float invariant; the third was about chasing the wrong recovery primitive (`--toggle float`) for hours when the right primitive (`manage=off` rules) was already in scope. **Read the docs before adding more code.**
