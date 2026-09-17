---
name: feedback-brewfile-drifts
description: The Brewfile is not ground truth — Karl installs and removes packages ad hoc without recording them
metadata:
  type: feedback
---

Karl installs and uninstalls brew packages outside the Brewfile and doesn't
always mention it ("I don't always tell you before I do stuff"). Audited
2026-09-16: 23 formulae and 16 casks were installed but unrecorded, while 4
formulae and 15 casks in the Brewfile were not installed at all.

**Why:** the Brewfile reads like a manifest, so it's tempting to treat it as the
state of the machine. It is a wish list that lags reality in both directions. The
dangerous direction is Brewfile-but-not-installed: `./setup` on a fresh machine
reinstalls things that were deliberately removed.

**How to apply:** when something depends on a package actually being present,
check `brew list --formula --installed-on-request` / `brew list --cask`, not the
Brewfile. When adding a config for a tool, confirm the tool itself is recorded —
herdr's config was tracked in one commit while the binary was missing from the
Brewfile until the next. Offer to reconcile drift, but don't sweep the lists in
unasked: much of the gap is deliberate one-offs, and guessing which is wrong.
Related: [[feedback-review-before-commit]], [[feedback-stop-guessing]].

Two `comm` gotchas when auditing: sort *after* stripping tap prefixes, not
before, or the comparison is silently garbage; and use `--installed-on-request`
rather than `brew leaves`, since a recorded formula that's also a dependency is
not a leaf.
