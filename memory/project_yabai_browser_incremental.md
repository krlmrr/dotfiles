---
name: project-yabai-browser-incremental
description: yabai browser array (fixed the "constantly misplacing / restart" pain) + incremental place_one on-open placement; why zero-motion is impossible
metadata:
  type: project
---

Two related yabai changes shipped 2026-07-15 (v1.0.95), all in `mac/yabai/yabairc`. Specs: `docs/superpowers/specs/2026-07-15-yabai-browser-array-design.md` and `…-incremental-placement-design.md`.

## Browser array — the fix for "constantly having to restart yabai"

Root cause of the constant window misplacement (and the restarts it drove): `external_correct()` **hard-required Zen** as the top-left window. Whenever the top-left browser was anything else (Chrome/Safari/Arc) or Zen wasn't running, the layout the user wanted was flagged WRONG, so **every** `place` trigger (any editor/browser/Ghostty window open/close) did a destructive full rebuild. Not tied to wake/dock — triggered by normal window activity.

Fix: generalized the hardcoded `Zen` role into `BROWSER_APPS` (newline-delimited so "Google Chrome" survives; generates `browser_sel` jq predicate + `BROWSER_RE` regex, mirroring `EDITOR_APPS`). New `browser_id()` = first open browser = the top-left slot occupant. `external_correct`/`place_editors` use it; `adopt` excludes the slot browser **by id** (a 2nd browser is still adopted). "Single browser only" — first open browser owns the slot. Live-proven: with Chrome in the slot, `place` now logs "trio correct — skip rebuild" instead of churning.

## Incremental `place_one` — one clean move on open (not a full rebuild)

On window open, `place_editors`' full teardown-rebuild (re-warp browser+Ghostty + `--balance`) was the "shuffle." Replaced the FOUR `window_created` signals (3 per-app `place` + catch-all `adopt` — which also double-fired) with ONE catch-all → `place_one $YABAI_WINDOW_ID`. `place_one` moves ONLY the new window relative to a cross-role anchor: slot-browser→west of editor, editor→east of browser, Ghostty→south of browser(fallback editor), stray/2nd-browser→`adopt` (south under editor); anchor-absent→leave as anchor. `place_editors` full rebuild stays for startup/display-change only. Live-verified: opening a window fires one `[one]` line (no rebuild, no double-fire); only the direct anchor **resizes** to yield space (dh change, no reposition) — inherent to tiling, not a shuffle.

## Why "zero visible motion" is impossible (don't retry)

yabai fires `window_created` **after** BSP has already tiled the new window — the window always appears at BSP's guess first, then we move it. The only pre-creation lever is the insertion point, which can't be conditioned on which app is opening AND is the documented parity coin-flip trap ([[project-yabai-insert-parity]]). So one BSP→slot hop is unavoidable; best achievable is "appears → one clean move." Ghostty placement is order-sensitive (only correct if the browser is already open); accepted, self-heals on rebuild.

## Latent, out of scope: LAPTOP_W/H stale

`external_idx()` treats any display != 2056×1329 as external. The laptop currently reports **3200×1800**, so the "external present" (stacked-trio on space 3) path runs even single-display. Not a bug for current use (it produces the layout the user likes), but if display logic misbehaves, check `LAPTOP_W`/`LAPTOP_H` first.

See [[project-yabai-wake-no-restart]], [[project-yabai-insert-parity]], [[project-yabai-pip-masquerade]], [[feedback-yabai-space2]], [[feedback-yabai-display-events]].
