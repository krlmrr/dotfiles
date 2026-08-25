# Browser-left invariant: collapsing yabai window placement

**Date:** 2026-08-25
**Status:** approved
**Touches:** `yabai/yabairc`

## Why

`yabairc` grew to 695 lines around a question that no longer matters: *which desk
does this window belong to?* It maintained two "managed desks" as peers, tracked a
sticky role-holder per desk, remembered every candidate's previous desk, and used
the difference between those two records to tell a drag from a fresh open — so it
could perform a cross-desk **swap**: drag an editor onto the browser's desk and
the config would send that desk's editor back the other way.

Desks are now moved between freely and by hand. Nothing needs to own a desk. One
thing does need to be true:

> **The browser is on the left.**

Everything else in the file existed to serve the retired question.

## The invariant

On every space with index >= 3, **the leftmost tiled window must be a browser.**

- Fewer than two tiled windows -> trivially satisfied, no action.
- No browser on the space -> nothing to enforce, no action. The right side is
  never constrained, so a desk without a browser is left entirely to bsp.
- Otherwise -> the minimum `frame.x` among browsers must equal the minimum
  `frame.x` among all tiled windows. Equality rather than strict ordering is
  deliberate: it means "a browser is in the left column", so a browser above a
  terminal in that same column still passes.

Spaces 1 and 2 are out of scope. Space 2 is `layout float` and yabai tiles
nothing there regardless.

### The squeeze guard

A window leaving a space can strand a split, leaving the survivors crammed into
one half with the other half empty. Relative-x comparison cannot see this, so the
check also requires the leftmost tiled window to actually reach the left edge
(`min(frame.x) <= 20`; `left_padding` is 12). Failing that forces a rebuild, whose
`--balance` is the repair. This guard applies only when a browser is present,
since without one there is nothing to rebuild from.

## Two browsers

No special case is needed. "A browser is leftmost" is satisfied by *either*
browser, so there is no tie-break to decide and no state to remember. The even
split the user asked for falls out of `split_type auto` plus `split_ratio 0.5`:

| Tiled windows | Container | `auto` splits | Result |
| --- | --- | --- | --- |
| 2 | 3176x1778, wider than tall | vertical | side by side, 50/50 |
| 3 | right half 1583x1778, taller than wide | horizontal | left column + right pair stacked |

Row 1 is "two browsers, split evenly". Row 2 is "browser keeps the left half,
everything else shares the right". `auto` draws the line exactly where the user
would — at the point a column stops being wider than it is tall. **Setting
`split_type vertical` would break row 2** by forcing three narrow columns, so it
stays `auto`.

## Horizontal splits

A reported full-width horizontal stack (VS Code above LM Studio) was not bsp's
choice. It was `adopt()`, which warped any window that held no role to `south` of
the desk's editor — by design. Deleting `adopt()` is the fix; `auto` then splits
that pair vertically because the container is wider than tall. No new rule.

## What is deleted

| Removed | Reason |
| --- | --- |
| `SLOT_FILE`, `slot_get/slot_set/slots_prune` | Sticky incumbents only served desk ownership |
| `reconcile()`, the cross-desk swap, insert-arming, ping-pong guards | Desks are moved by hand now |
| `elect()` | Replaced by "leftmost browser" |
| `adopt()` | The right side is unconstrained |
| `ghostty_on()` | Ghostty has no role |
| `EDITOR_APPS`, `editor_sel`, `EDITOR_RE` | There is no editor role |
| `browser_sel`, `BROWSER_RE` | Membership is tested with `jq --arg` against `BROWSER_APPS` |
| `external_idx`, `LAPTOP_W/H`, `DESKS_CACHE`, `desk_spaces`, `is_managed` | Replaced by one numeric test |
| `SIG_FILE`, `on_display_change`'s signature gate | Nothing is keyed by space index, so a dock needs no state reset |
| `shape_correct`'s shape table, `arrange`'s branches | One invariant, one warp |

Three `/tmp` state files become two.

## What is kept, and why

`warp_to` and its support cast — `pair_geom`, `dir_ok`, `wait_moved`,
`space_visible`, `ensure_tiled`, `floating`, `stuck_clear`, `STUCK_FILE`,
`WARP_SETTLE` — survive unchanged. That machinery makes a warp actually stick
(axis repair via `--toggle split`, order repair via `--swap`, parking repairs
proven useless, deferring geometry work while a space is off-screen). It is
orthogonal to what is being deleted and was expensive to get right.

The `place` lock stays: signals still arrive in bursts and two concurrent runs
would interleave.

`SEEN_FILE` is **kept, in reduced form** — a plain `id:space` memo, with none of
its former origin/swap semantics. It exists solely to gate `window_moved`, which
fires continuously during a drag. Without the gate, dragging a non-browser
leftward would trip the invariant mid-drag and warp the window out from under the
cursor. The gate restricts action to a genuine change of space, which is exactly
the "move an editor onto the browser's desk" case.

## Signals

| Event | Action |
| --- | --- |
| `window_created` | check that window's space |
| `window_moved` | check, gated on a real space change |
| `space_changed` | check the newly focused space |
| `window_destroyed` | `space --balance` (repairs a stranded split; the invariant cannot be broken by a close) |
| `display_*` | check every space >= 3 (idempotent; the lock absorbs duplicate dock events) |
| startup | check every space >= 3 |

Balance runs only when a rebuild actually happened, so manual resizes survive a
desk revisit.

## Core rule, retained

Location is still truth. The config never moves a window between spaces — with
`reconcile()` gone, no code path can. It only arranges what it finds.
