# yabai: incremental on-open placement

Date: 2026-07-15 · Scope: `mac/yabai/yabairc` only

## Problem

When a new window opens, `place_editors` runs a full teardown-rebuild of the
trio — it re-warps the browser AND Ghostty and runs a global `--balance` even
when only the one new window is out of place. Combined with `warp_to`'s
self-correcting warp→toggle-split→swap, a single window open produces several
visible repositions ("the shuffle").

Verified live 2026-07-15: opening one Ghostty window logged a single
`place(window): rebuild stacked` — one full rebuild — and the new window first
appeared where BSP dropped it (bottom-right), then the rebuild moved it.

**Hard constraint (why zero-motion is impossible):** yabai fires
`window_created` AFTER it has already BSP-tiled the new window. We never get
control before the window is on screen. The only pre-creation lever is the
insertion point, which (a) can't be conditioned on which app is opening and
(b) is the documented parity-coin-flip trap this config deliberately abandoned
(see [[project-yabai-insert-parity]]). So the window always appears at BSP's
guess first. The achievable goal is: **appears once, then makes ONE clean move
into its slot — nothing else on screen budges.**

## Goal

On a window opening, place ONLY the newly-created window (its id arrives via
`$YABAI_WINDOW_ID`) relative to a stable anchor, with a single `warp_to`. Leave
already-correct windows untouched. No global `--balance` on the open path.

## 1. New `place_one <id>` router

Runs for every `window_created`. Guards mirror `adopt`: the window must be
`AXStandardWindow`, not `Picture-in-Picture`, not floating — else return
(float/PiP/phantom left alone). `target=$(editor_space)`; return if empty.

Classify by app and place relative to a **cross-role anchor** so the result is
independent of the order windows open in:

| New window | Anchor | Placement (one `warp_to`) |
| --- | --- | --- |
| browser, and it is the slot occupant (`browser_id`==id) | the editor (`editor_ids` head) | warp **west** of editor |
| browser, but another browser already holds the slot (2nd browser) | — | fall through to `adopt` (tuck south under editor) |
| editor | the browser (`browser_id`) | warp **east** of browser |
| Ghostty | browser if present, else editor | warp **south** of that anchor |
| anything else (stray) | — | `adopt` (tuck south under editor) |

**Anchor-absent case:** if the anchor window doesn't exist (e.g. a browser opens
with no editor yet, or the first editor opens with no browser), do NOT warp —
the window stays where BSP put it and becomes the anchor for whatever opens
next. This is what makes the browser/editor pair assemble correctly regardless
of open order: browser-then-editor and editor-then-browser both end with
browser-west / editor-east, because each new arrival warps relative to the one
already there.

**Ghostty is order-sensitive (accepted):** Ghostty anchors to the browser
(preferred) or the editor (fallback). If Ghostty opens while a browser is
already present, it lands bottom-left under the browser — the correct slot. If
it opens *before* the browser, it anchors to the editor and lands south of it
(bottom-right); a later browser open does not re-move it (that would violate
"only the new window moves"). The steady state (browser already open) is
correct; the unusual before-browser order self-heals on the next
`startup`/`display-change` rebuild. We accept this rather than move a second
window on every Ghostty open.

**Space consolidation:** for trio members (browser/editor/Ghostty) that opened on
a space other than `target`, move them to `target` first
(`yabai -m window <id> --space <target>`), then `ensure_tiled`, then warp. Strays
are only handled when already on `target` (unchanged from `adopt` — strays are
never yanked across spaces).

**Only the new window moves.** Every branch warps `<id>` (the new window) onto an
existing anchor; no other window is repositioned. `warp_to` keeps its internal
verify+repair (so the one window may take 1–2 quick corrective ops), because we
are NOT reintroducing insert-priming.

## 2. `adopt` reused, not duplicated

`adopt` is unchanged and becomes the shared "tuck a stray south under the editor"
helper. `place_one`'s stray / 2nd-browser branch calls `adopt <id>` directly —
`adopt`'s existing guards already (a) exclude editors/Ghostty by app, (b) exclude
the slot browser by id, and (c) require an editor to be open and the window to be
on `target`. A 2nd browser window (id != `browser_id`) correctly passes those
guards and gets tucked. `place_editors`' trailing stray sweep keeps calling
`adopt` exactly as today.

## 3. Signal collapse (also fixes a double-fire)

Today `window_created` registers FOUR signals: three per-app `place` (full
rebuild) plus the catch-all `adopt` — so opening an editor/browser/Ghostty fires
both a rebuild and an adopt. Replace all four with ONE:

```sh
yabai -m signal --add event=window_created action="… yabairc place-one $YABAI_WINDOW_ID"
```

(dispatch case gains `place-one) place_one "$2" ;;`).

**Unchanged — still full-rebuild:** `startup` and `display-change` keep calling
`place_editors` (infrequent, one-time; a rebuild there is acceptable). The
`window_destroyed app=$EDITOR_RE → place` signal and the
`window_destroyed → space --balance` signal are unchanged — closing a window is
out of scope (the reported pain is on open).

## Out of scope / accepted trade-offs

- **The one BSP→slot hop** remains (yabai event timing; see Problem). Not fixable
  without insert-priming, which is rejected.
- **Split ratios** may be uneven without the global `--balance`; positions are
  correct. `startup`/`display-change` rebuilds still balance. Accepted — balancing
  on every open is exactly the motion we're removing.
- **Multiple windows of one role** (2nd editor, etc.) are best-effort: they warp
  relative to the cross-role anchor and land in the right region, but fine
  intra-column arrangement is left to BSP, matching today's behavior (the current
  rebuild only positions the first editor).
- No change to `external_correct`, the trio geometry definition, space 2 float,
  PiP handling, or SIP/SA gating.

## Success criteria

- Opening a browser / Ghostty / stray results in that window making a single move
  into its slot; the other trio windows do not visibly reposition (verified by
  watching `/tmp/yabai.log` and window frames before/after — only the new
  window's frame changes).
- Opening order does not change the final browser/editor pair (browser-west /
  editor-east) for the singleton case. (Ghostty's slot is order-sensitive by
  design — see trade-offs.)
- Exactly one `window_created` handler fires per open (no place+adopt
  double-fire).
- A stray still tucks south under the editor; the slot browser is never tucked.
