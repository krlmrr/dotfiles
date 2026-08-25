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

On every space with index >= 3, **the browser owns the top-left** — precisely, the
topmost window of the leftmost column is a browser.

- Fewer than two tiled windows -> trivially satisfied, no action.
- No browser on the space -> nothing to enforce, no action. The right side is
  never constrained, so a desk without a browser is left entirely to bsp.

Spaces 1 and 2 are out of scope. Space 2 is `layout float` and yabai tiles
nothing there regardless.

### Two weaker rules, both tried, both wrong

This landed on the third attempt. Recording the first two because each looks
correct on paper and each produced a layout that had to be thrown out.

**"A browser is somewhere in the leftmost column"** (equality on min x). Accepts
an *editor* sitting on top of the browser in that column — observed live: Code at
(12, 37) with Zen beneath it at (12, 916) satisfies the test. Not what "the
browser is on the left" means.

**"The leftmost browser is strictly left of every non-browser."** Manufactures
columns. Any non-browser landing in the browser's own column reads as a
violation, and the only repair strict admits is warping the browser further west
— so browser + terminal + editor converges on three equal columns. Observed live
and rejected immediately; it was worse than the problem it solved. The lesson is
that a rule's *repair* is part of the rule: strict's only move added a column, and
adding a column can never be the fix for "something shares my column".

**Top-of-leftmost-column** accepts "browser top-left, anything below it, anything
to the right", rejects an editor above the browser, and repairs the common case
without a new column.

### Repair directions

The direction is chosen from the violation, and this is what keeps the rule from
splitting the screen:

| Case | Direction | Effect |
| --- | --- | --- |
| A browser is in the left column but not at its top | `north` | Moves it up *within* the column. Adds no column. |
| No browser in the left column at all | `west` | A new leftmost column, which here is genuinely correct. |
| Squeeze guard only (see below) | none | `--balance` alone is the repair. |

### The squeeze guard

A window leaving a space can strand a split, leaving the survivors crammed into
one half with the other half empty. Relative-x comparison cannot see this, so the
check also requires the leftmost tiled window to actually reach the left edge
(`min(frame.x) <= 20`; `left_padding` is 12). Failing that forces a rebuild, whose
`--balance` is the repair. This guard applies only when a browser is present,
since without one there is nothing to rebuild from.

## Two browsers

No special case is needed. With only browsers on a space there is no non-browser
for them to be left of, so the invariant is silent and neither browser has to win
a tie-break. No state to remember. The even split falls out of `split_type auto`
plus `split_ratio 0.5`:

| Tiled windows | Container | `auto` splits | Result |
| --- | --- | --- | --- |
| 2 | 3176x1778, wider than tall | vertical | side by side, 50/50 |
| 3 | right half 1583x1778, taller than wide | horizontal | left column + right pair stacked |

Row 1 is "two browsers, split evenly". Row 2 is "browser keeps the left half,
everything else shares the right". **Setting `split_type vertical` would break row
2** by forcing three narrow columns, so it stays `auto`.

One caveat, learned the hard way: `auto` decides at *insertion* time from the
container being split then, and an explicit `--warp` afterwards overrides whatever
it chose. So this table describes what bsp does when left alone — it is not a
guarantee about the final tree. The three-equal-columns layout that killed the
strict rule was produced by the rule's own west-warp, not by `auto`.

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

## Verification

The invariant's jq program is exercised by 21 fixture cases. Four of them are the
exact layouts that drove the design — the editor-above-browser screenshot (must
repair `north`), the three-equal-columns screenshot (must NOT be produced), the
browser-top-left-with-two-below layout that is fine as it stands, and the approved
browser-left-half preview. The rest cover an empty space, single windows, a
right-hand browser (must repair `west`), a left column containing no browser, the
topmost browser being chosen when a column holds several, the squeeze guard with
and without a browser, floating / Picture-in-Picture / non-standard-subrole
exclusion, multi-word app names, and two browsers alone.

The harness extracts the jq straight out of `yabairc`, so it cannot drift from
what actually runs.

Fixtures rather than live windows, deliberately: driving real windows to test
this disrupts whoever is using the machine.

## Core rule, retained

Location is still truth. The config never moves a window between spaces — with
`reconcile()` gone, no code path can. It only arranges what it finds.
