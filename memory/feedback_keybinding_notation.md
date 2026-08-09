---
name: feedback_keybinding_notation
description: Write key chords as cmd+X, never cmd-X — hyphen separators get eaten by font ligatures
metadata:
  type: feedback
---

Karl writes key combos with a **plus** separator (`cmd+>`, `cmd+shift+p`). Always use that form. Never use the hyphen form (`cmd->`, `cmd-shift-p`) even when quoting docs that do — restate them with `+`.

**Why:** Karl has font ligatures enabled in his editor and terminal, so `->` renders as a `→` glyph. On 2026-07-28 I passed along Zed's documented binding for `agent::AddSelectionToThread` as `cmd->`; it displayed as "cmd →" and he pressed cmd+right-arrow, concluding the feature was broken in vim mode. It worked fine all along. Zed's own docs use hyphen separators throughout, so this will recur on any Zed keybinding.

**How to apply:** Translate hyphen-style chords to plus-style before showing them. Watch especially for chords whose key is itself punctuation (`>` `-` `=` `<`), where the separator and the key are visually indistinguishable — spell those out ("cmd+shift+period") if there's any doubt. Related: [[user_editor_choice]] (Zed and VS Code are the editors this comes up in).
