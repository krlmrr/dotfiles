---
name: feedback-editor-config-global
description: Editor/tooling config belongs in the dotfiles user-level settings, not in a project's .vscode or equivalent
metadata:
  type: feedback
---

Put editor and language-server configuration in the user-level settings tracked
in this repo (`vscode/settings.json`, `zed/`), never in a per-project `.vscode/`
or equivalent — even when the annoyance only shows up in one codebase.

**Why:** "if I change editors or I change codebases I don't want to have to go
and fix it again." Per-repo config is invisible work that has to be redone in
every new project and is lost entirely on an editor switch (see
[[user-editor-choice]] — VS Code and Zed both stay in play).

**How to apply:** when a fix could land either place, default to the dotfiles
user settings and say so. Only touch a project's own config when the setting is
genuinely project-specific (a path, a PHP version) or the user asks. Note that
VS Code object-valued settings do not deep-merge: a project's
`.vscode/settings.json` replaces the user-level value wholesale, so an existing
project-level block can mask the global one.
