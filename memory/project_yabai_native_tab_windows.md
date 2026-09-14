---
name: project_yabai_native_tab_windows
description: A background macOS native tab is absent from `query --windows` yet still holds a BSP tile; how to detect one and why its own .space is a lie
metadata:
  type: project
---

**2026-09-01 — TablePlus "two connections, half the column blank", root-caused.**

A macOS native tab is a real `AXStandardWindow`, so yabai gives every tab its own
tree node and the background ones hold empty tiles. They are invisible to every
predicate in `yabairc` because those all iterate `query --windows`, which **omits
a background tab entirely** — while `query --windows --window <id>` still returns
it in full. That is the exact inverse of an AX-dead record, so the two are
cleanly separable and neither repair can fire on the other:

| in `query --windows` | `--window <id>` resolves | meaning |
| --- | --- | --- |
| yes | yes | ordinary window |
| yes | **no** | AX-dead phantom — see [[project_yabai_ax_loss]] |
| **no** | **yes** | **background native tab** |
| no | no | genuinely gone |

**A background tab's own `.space` is a lie.** yabai reports the **focused** space
for a window it cannot find in any space list. Verified: tab 48206 read
`space: 2` while its frontmost sibling sat on space 3 and space 2's own `windows`
array did not contain it. Trusting it floats windows on space 2, which is never
ours to touch — see [[feedback_yabai_space2]]. `tab_space()` proves the space two
other ways instead (a managed space's tree extreme, or unanimous agreement among
listed windows of the same pid) and skips when neither proves it.

**Enumeration is the hard part** and is not complete. Background tabs appear in
no listing, so candidates come from a ledger written at `window_created` /
`window_focused` plus each managed space's tree extremes. A tab that predates the
config load *and* sits interior to the tree is invisible until focused once.
Self-heals on first use of each tab, not immediately.
