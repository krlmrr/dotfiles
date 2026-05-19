---
name: Never killall Dock from Hammerspoon directly
description: Running killall Dock inside hs.execute crashes Hammerspoon - use external shell scripts instead
type: feedback
---

Never run `killall Dock` directly from Hammerspoon's `hs.execute`. It kills Hammerspoon's connection to the Dock and crashes it.

**Why:** Hammerspoon maintains a persistent connection to the Dock via AppKit. `killall Dock` interrupts that connection, causing `Dock connection error: Connection interrupted` and a crash.

**How to apply:** Put any `killall Dock` calls in external shell scripts and run them with `hs.execute("path/to/script.sh &", true)`. Same applies to inline `osascript` calls that modify dock state — run them as external scripts.
