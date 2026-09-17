---
name: feedback-pass-silently-fail-loudly
description: Karl wants scripts silent on success and loud on failure — no "nothing to do" chatter, but never a swallowed error
metadata:
  type: feedback
---

Pass silently, fail loudly. A script that did nothing should say nothing; a
script that failed should be impossible to miss. Stated 2026-09-15 after every
`brewup` printed six lines of "yabai not upgraded", "Nothing to prune — already
clean", "restoring focus to MSTeams".

**Why:** Routine no-op output trains you to skim past the whole block, which is
exactly when a real failure slips through unread. Noise costs attention, and
attention is what makes the loud case work.

**How to apply:** Gate the *steady-state* lines, never the failure ones. Defer
headers/banners until there is something to report rather than printing them
up front. Keep failures on stderr with a non-zero exit. A `--dry-run` or
explicit diagnostic invocation stays verbose — that is someone asking to see
everything. When adding a quiet mode, verify BOTH halves: zero output when
clean, and the failure path still speaking. Related: [[feedback-minimal-comments]].
