---
name: No sleep, no guessing timings
description: Never use sleep or arbitrary delays to solve timing issues - find the actual fix instead
type: feedback
---

Don't use `sleep` or arbitrary timer delays to work around timing issues. They're fragile and usually mask the real problem. Find the actual solution first.

**Why:** Spent a long time chasing a macOS dock gap issue with increasingly long sleep timers when the real fix was running an AppleScript toggle trick in a background shell script with no delay at all.

**How to apply:** When something isn't working, don't assume it's a timing issue. Test the actual mechanism first (does it work from the terminal?), then figure out why it doesn't work in context (permissions, execution environment, etc.). If a shell command works from the terminal but not from Hammerspoon's `hs.execute`, try running it as an external script instead.
