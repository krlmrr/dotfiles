---
name: user_editor_choice
description: Karl's code editors are VS Code and Zed only — JetBrains/PhpStorm dropped
metadata:
  type: user
---

Karl codes exclusively in **VS Code** or **Zed** going forward. JetBrains is done — PhpStorm and all JetBrains tooling were fully removed on 2026-07-06 (Library data ~19GB, plists, dotfiles `mac/phpstorm/` config, IdeaVim symlinks, the `ps.` alias, and yabai's PhpStorm `editor_sel`/rule references).

**Why:** He's done with language-specific IDEs (PhpStorm = PHP-locked). Prefers general-purpose editors so it's one editor, one set of keybindings and muscle memory, across every language.

**How to apply:** Treat "the editor" as Zed or Code. Don't reintroduce PhpStorm/JetBrains config, aliases, or window rules. yabai's `editor_sel` is now `(.app=="Zed" or .app=="Code")` — keep it that way. See [[feedback_no_aerospace]] for the general pattern: Karl commits to tools and doesn't want rejected ones pitched back.
