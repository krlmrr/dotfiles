---
name: Release script auto-prefixes v
description: ./release auto-adds the v prefix, so passing 1.0.XX or v1.0.XX both work
type: feedback
originSessionId: e8651f75-3f69-4832-a7cc-96c850e17663
---
`./release` (top-level, not `release.sh`) auto-prefixes `v` and strips one if you double it. Either `./release 1.0.75` or `./release v1.0.75` produces tag `v1.0.75`.

**Why:** Earlier the script took the arg as-is and double-`v` tags (`vv1.0.50`) slipped through. Auto-prefix landed in commit c0decfb.

**How to apply:** Check latest tag with `git tag --sort=-v:refname | head -1`, bump the patch number, and pass either form to `./release`. Don't worry about the leading `v`.
