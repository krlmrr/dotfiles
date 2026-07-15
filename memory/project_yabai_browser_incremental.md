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

yabai fires `window_created` **after** BSP has already tiled the new window — the window always appears at BSP's guess first, then we move it. The only pre-creation lever is the insertion point, which can't be conditioned on which app is opening AND is the documented parity coin-flip trap ([[project-yabai-insert-parity]]). So one BSP→slot hop is unavoidable; best achievable is "appears → one clean move."

### Topology-flip fix (2026-07-15, commit b4e16cb) — why place_one is a HYBRID

The first incremental `place_one` moved only the new window relative to a cross-role anchor. That broke on **editor open**: an editor's presence flips the trio's whole topology (browser|Ghostty **side-by-side** with no editor ↔ browser/Ghostty **stacked** in the left column + editor full-right). A single warp can't restructure that — a new editor got warped "east of browser" into a side-by-side layout and produced a **3-column wedge** (Zen|Code|Ghostty) that persisted until a restart, because only startup/display-change rebuild.

Fix: `place_one` now splits windows into **structural** (editor, slot browser — presence changes topology) → run the full `place_editors` rebuild (which self-skips when already correct, so no gratuitous shuffle); and **append-only** (Ghostty, strays, 2nd browser) → single incremental warp, then **self-heal**: re-check `external_correct` and rebuild if the incremental result left the trio wrong. So a bad incremental placement can never persist to the next restart. Ghostty append stays smooth (no shuffle when it lands correct). Editor-open shuffles only when the layout is actually wrong.

## Display topology (corrected 2026-07-15 — earlier note was WRONG)

Daily driver is an **Apple Studio Display** (5120×2880 native, reported by yabai as **3200×1800** at "more space" scaling; usually the sole display, laptop in clamshell). `LAPTOP_W/H=2056×1329` correctly identifies the MacBook's built-in panel and is NOT stale. So the "external present → stacked trio on space 3" path is the **intended docked behavior** on the Studio Display, not an accident. Laptop-only (away from the Studio) → `external_idx` empty → apps break out to separate desktops 3/4/5.

An earlier version of this note claimed 3200×1800 was "the laptop" and LAPTOP_W/H was stale — that misdiagnosis sent a whole debugging session chasing a phantom. 3200×1800 is the **Studio Display**.

**Apple TV (AirPlay, 1920×1080):** connects rarely for casting fullscreen video. When present it's a 2nd/3rd display; the trio-placement logic doesn't distinguish it from a work monitor, so a cast can transiently scramble the Studio trio (recovered by one `yabairc place` or opening a trio window). Deliberately NOT handled (2026-07-15) — too rare to be worth a UUID/resolution exclusion.

See [[project-yabai-wake-no-restart]], [[project-yabai-insert-parity]], [[project-yabai-pip-masquerade]], [[feedback-yabai-space2]], [[feedback-yabai-display-events]].
