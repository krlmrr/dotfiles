---
name: project-yabai-ax-loss
description: yabai losing AX access is the mechanism behind "empty-subrole phantom windows" and the desk-restacks-on-every-visit loop; plus why WARP_SETTLE measured load-bearing then not
metadata:
  type: project
---

**2026-08-17 — the "desk 3 restacks every time I go to it" bug, root-caused.**

**Mechanism (this is the thing to remember).** When yabai loses Accessibility
access to a window, that window reports `role==""` and `subrole==""`, and
`yabai -m query --windows --window <id>` answers *"could not locate window"* —
but it **stays in the space's `windows` array at its old tile geometry**. Every
predicate in `yabairc` filters on `subrole=="AXStandardWindow"`, so such a window
is invisible to all of them while still occupying screen area. The layout logic
then chases a shape it cannot see, and since `space_changed → place` fires on
every arrival, you get **exactly one futile repair step per visit, forever** —
which is what "restacks every time" actually is.

This is the same thing the "transient lowercase-`ghostty` empty-subrole window"
sighting in [[project-yabai-browser-incremental]] was; it does not vanish, it is
an AX-dead window record.

**AX loss can be total and is silent.** Mid-diagnosis a `yabai --restart-service`
came up with **all 12 windows unreadable** — yabai managing nothing at all, no
error anywhere. The next restart recovered 10/12. The binary was untouched since
May (not a brew-upgrade TCC invalidation), so the grant was intact; the process
just came up untrusted. **If yabai "does nothing", check
`query --windows | jq '[.[]|select(.role=="")]|length'` before anything else** —
a load-time `WARNING: N window(s) unreadable` line now logs this.

Truly dead records survive restarts: `1808/ghostty` and `6196/TablePlus`
persisted as unreadable across three, from apps whose real windows were long gone.

**Geometry cannot be verified on an off-screen desk.** `pair_geom` reports
**pre-op frames** for a space that is not `is-visible` — yabai does not apply or
report the relayout until you arrive. So `warp_to`'s `--toggle split` / `--swap`
repairs, which decide from geometry, were firing **blind** on off-screen desks.
This — not any settle duration — is why the post-warp settle measured
"load-bearing" in b2de9ab and then "8/8 clean without it" in 57f1581: it depended
on whether the desk under test happened to be on screen. **No `WARP_SETTLE` value
can fix it**, consistent with [[feedback-no-sleep]]. Repairs are now gated on
`space_visible` and deferred to the arrival trigger.

Cost of the gate: the `space_changed` signal fires *before* the space reports
visible, so the first arrival after a perturbation defers and the **second**
arrival converges. Strictly better than a permanent restack; fixable later by
polling visibility only when the trigger is `space_changed` (do NOT poll on the
ordinary off-screen desk sweep — that is the common path).

**Two fixes that sounded right and are WRONG** (both disproven live, don't retry):
- *"Count phantom nodes in `warp_to`'s sibling heuristic."* Phantoms are **not**
  tree nodes — `query --spaces --space 3` gave `first-window: 6095,
  last-window: 6192`, only the real pair. The existing subrole filter excludes
  them correctly; counting them would force spurious warps.

**2026-08-25 — `adopt` is GONE, and the reason it existed is gone with it.** The
2026-08-17 note here used to describe narrowing `adopt` from a per-trigger sweep
to creation-only, because the sweep was dragging hand-placed windows back under
the editor. That was treating the symptom. `adopt` warped any roleless window
`south` of the desk's editor **by design**, which is what produced every reported
"full-width horizontal stack" (the last sighting: VS Code above LM Studio). The
whole editor role and `adopt` with it are deleted as of the browser-left rewrite —
see [[project-yabai-browser-left]] and
`docs/superpowers/specs/2026-08-25-browser-left-invariant-design.md`. If a
surprise top/bottom split ever reappears, it is NOT `adopt` any more: check
`split_type` is still `auto`.

**What shipped:** `space_visible` gate + a geometry-keyed no-progress breaker
(`/tmp/yabai_stuck`, cleared at load and on display-change) that parks a repair
which **moved nothing at all** — "moved but still wrong" is progress and is never
parked. Progress is confirmed by `wait_moved`, a bounded condition poll, because
"cannot observe the move yet" and "the move never happened" read identically.
Regression test (18 assertions, stubs the yabai boundary and drives `warp_to`
through park → re-arm → clear) is NOT in the repo — it lived in the session
scratchpad; rewrite it if you touch `warp_to`.

See [[project-yabai-browser-left]], [[project-yabai-browser-incremental]],
[[project-yabai-insert-parity]], [[feedback-no-sleep]],
[[project-yabai-wake-no-restart]].
