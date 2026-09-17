---
name: feedback-dont-automate-unfelt-pain
description: Don't build automation for a problem Karl hasn't actually been frustrated by yet
metadata:
  type: feedback
---

Karl, on talking himself out of adding a herdr server-restart nudge to `brewup`
(2026-09-16): "I am also automating something that hasn't frustrated me yet."

**Why:** every branch added to a maintenance script is permanent surface area —
it has to keep working, stay correct as the tool changes, and gets read every
time someone opens the file. A problem encountered once and already understood
doesn't earn that. `brewup`'s existing branches all trace back to real recurring
pain (yabai's SA breaking on upgrade, Raycast quitting when its cask is replaced).

**How to apply:** before proposing automation, ask whether the problem has
actually recurred. Evidence of real staleness or repeated breakage justifies it;
"this could go wrong someday" does not. When only part of a proposal passes that
test, say which part and drop the rest rather than shipping both. Related:
[[feedback-minimal-comments]], [[feedback-pass-silently-fail-loudly]].
