---
name: no-aerospace-suggestions
description: User has evaluated AeroSpace and rejected it as a yabai replacement — do not suggest it again
type: feedback
---

When complexity or pain points come up in the yabai config, do **not** suggest AeroSpace as an alternative. User has already evaluated AeroSpace and it doesn't do what they want.

**Why:** AeroSpace gives up native macOS spaces in favor of its own virtual workspaces. The user's workflow depends on real macOS spaces (Mission Control integration, native gestures, multi-monitor space-per-display behavior, etc.) and the workspace-substitution model breaks more than it fixes for them.

**How to apply:** When asked about reducing yabai config complexity or fixing yabai pain points, focus on (a) simplifying within yabai, (b) fixing the specific issue with yabai's own mechanisms, or (c) other helpers that augment yabai (skhd, sketchybar, custom shell scripts) — NOT switching tools. Do not pitch AeroSpace, Amethyst, or other tiling-WM replacements unless the user explicitly asks for alternatives.
