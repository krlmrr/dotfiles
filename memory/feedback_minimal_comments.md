---
name: feedback-minimal-comments
description: Karl wants minimal comments — don't add explanatory comment blocks just because code changed
metadata:
  type: feedback
---

When editing config/scripts in this repo, don't add multi-line comment blocks explaining a change. Karl pushed back on a 6-line comment added just to justify deleting one line in `yabairc`.

**Why:** The code should speak for itself; verbose rationale comments are noise. Git history/commit messages carry the "why".

**How to apply:** Make the minimal edit. Add a comment only when the behavior is genuinely non-obvious to a future reader, and keep it to one terse line. Don't narrate removals or restate what the code does. Related: [[feedback-stop-guessing]].
