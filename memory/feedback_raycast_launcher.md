---
name: raycast-launcher
description: Karl uses Raycast as his primary launcher; prefer Raycast script commands over terminal aliases for launchable actions
metadata:
  type: feedback
---

When adding ways to launch apps or run shell actions, default to **Raycast script commands** (or quicklinks), not zsh aliases.

**Why:** Karl explicitly said "I am not going to launch my browser from Ghostty... I am just going to use Raycast like I always do." Terminal aliases for launch-style actions are dead weight in his workflow.

**How to apply:** If the user asks for a launcher, app opener, or one-shot command they'd trigger by name, build a Raycast script command (`.sh` with `# @raycast.*` header comments) and tell them how to register the containing directory in Raycast → Extensions → Script Commands. Reserve shell aliases for things you actually run in the terminal (git/build shortcuts, etc.).
