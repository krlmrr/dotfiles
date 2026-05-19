---
name: Yabai space 2 is intentionally unmanaged
description: When working on yabai in dotfiles, exclude space 2 from any window-targeting logic or diagnostics — it is the float-layout chat space and should never be touched
type: feedback
originSessionId: d0ec74d1-bfbc-4a04-9c96-dad29211719d
---
Space 2 (label `chat`) is configured as `layout float` in `mac/yabai/yabairc` and intentionally hosts chat apps (Slack, Discord, Telegram, Messages, Microsoft Teams, Tuple). It must NEVER appear in yabai window-management fixes, diagnostics, or filters.

**Why:** The user has had to point this out more than once. Listing space 2 windows in diagnostic output or including them in any retile/toggle/sweep logic reads as not paying attention to their setup.

**How to apply:** When querying or scripting against yabai windows in this repo, filter out space 2 windows by default (e.g., `select(.space != 2)`) and don't echo them in diagnostic dumps. When reading yabairc, the float-layout config for space 2 is the authoritative signal — respect it.
