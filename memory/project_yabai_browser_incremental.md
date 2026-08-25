---
name: project-yabai-browser-incremental
description: yabai display topology (Studio Display is 3200x1800, not the laptop) and why zero-motion window placement is impossible; the trio/slot architecture this file used to document is superseded
metadata:
  type: project
---

**SUPERSEDED ARCHITECTURE — read this first.** This file used to document the
trio/slot design: `EDITOR_APPS` + `BROWSER_APPS` as priority lists, a sticky slot
holder per desk, `place_editors`/`place_one`/`adopt`/`reconcile`, Zen exile and
promotion, dual-project mode, personal-desk parity, and cross-desk swaps. **All of
it was deleted on 2026-08-25** in favour of a single invariant — see
[[project-yabai-browser-left]]. Do not reason about yabairc from the old model;
there is no editor role, no slot, no managed-desk pair, and no cross-desk
movement. What is kept below are the two findings that outlived the design.

## Display topology (corrected 2026-07-15 — an earlier note was WRONG)

Daily driver is an **Apple Studio Display** (5120x2880 native, reported by yabai as
**3200x1800** at "more space" scaling; usually the sole display, laptop in
clamshell). An earlier version of this note claimed 3200x1800 was "the laptop" —
that misdiagnosis sent a whole debugging session chasing a phantom. It is the
Studio Display. The MacBook's built-in panel reports **2056x1329**.

`LAPTOP_W`/`LAPTOP_H` and `external_idx` no longer exist in `yabairc` (nothing is
keyed by display or space identity any more), but the numbers are recorded here
because they are the ones to use if display detection is ever reintroduced.

**Apple TV (AirPlay, 1920x1080):** connects rarely for casting fullscreen video.
When present it is an additional display. Deliberately not special-cased.

## Why "zero visible motion" is impossible (don't retry)

yabai fires `window_created` **after** BSP has already tiled the new window — the
window always appears at BSP's guess first, then any correction moves it. The only
pre-creation lever is the insertion point, which cannot be conditioned on which
app is opening AND is the documented parity coin-flip trap
([[project-yabai-insert-parity]]). So one BSP-then-correct hop is unavoidable; the
best achievable is "appears, then one clean move." Under the browser-left rule
this is rarer than it was, because a window that does not break the invariant is
never moved at all.

See [[project-yabai-browser-left]], [[project-yabai-ax-loss]],
[[project-yabai-insert-parity]], [[project-yabai-pip-masquerade]],
[[feedback-yabai-space2]], [[feedback-yabai-display-events]].
