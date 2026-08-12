# yabai: location is truth (per-desk slots, sticky incumbents, desk swap)

Date: 2026-08-11 · Scope: `mac/yabai/yabairc` only

## Problem

Placement resolves windows **globally** and then drags them to where it thinks
they belong. Two rules do the damage:

1. `browser_id()` asks "highest-priority browser *anywhere*?" — `BROWSER_APPS`
   order decides — and `place_editors()` hard-moves that window to the work desk
   on every `place` trigger (`window_created`, `window_destroyed` for any editor
   or browser, `space_changed`, display changes).
2. `place_zen()` exiles every Zen window to `zen_space` unless it holds the slot.

Reported live 2026-08-11: user dragged Chrome to desk 4 to work on NotaryDash
alongside VS Code. Chrome was pulled back to desk 3 on the next signal, leaving
desk 4 with no browser. The user's placement loses to a hard-coded priority list
every time.

Two further cross-desk drags are the same class of bug:

- **Editor deport** — `place_editors()` moves every editor on the work desk except
  the oldest (`eds_on | tail -n +2`) to `zen_space`.
- **Single-editor adoption** — when the work desk has no editor and exactly one
  editor exists anywhere, it is dragged to the work desk. Close the desk-3 editor
  in a two-desk setup and the surviving desk-4 editor is yanked off its desk.

Underlying all of it: **"oldest window id" is the wrong proxy for "the window that
matters."** It is a stability hack — yabai returns windows newest-first, so the
naive pick let every new window seize the slot and evict the incumbent. Sorting by
id inverted the failure: the incumbent is now permanently the oldest window and the
slot can never be re-elected, no matter what the user does.

## Goal

One rule, applied at both levels:

> **Where a window is, and what the user did to it, decides its role.
> The config never moves a window the user did not move.**

- **Across desks** — a desk is arranged from what is already on it. Nothing is
  dragged between desks by the config.
- **Within a desk** — the slot holder is a sticky incumbent that survives new
  windows, and is re-elected only when it leaves or closes.
- **User-initiated** — dragging a window onto an occupied desk **swaps** with the
  incumbent, sending it back to the desk the newcomer came from.

## 1. Per-desk resolution

`browser_id()` (global) → `browser_on(space)`: the highest-priority browser window
**already on that space**, `BROWSER_APPS` order breaking ties, then window id.

`BROWSER_APPS` stops deciding which desk a browser lives on. It now only decides
who owns the top-left slot when two browsers share one desk.

Same shape for editors (`editor_on(space)`) and Ghostty (`ghostty_on(space)`).

### Zen stops being special

Delete `place_zen()`, `ZEN_APP`, the Zen branch in `place_one()`, and the Zen entry
in `adopt()`'s skip guard. Zen becomes an ordinary `BROWSER_APPS` entry. Put Zen on
desk 3 and it is desk 3's browser.

### `place_personal()` and the work-desk path collapse

`place_personal()` exists *only* because Zen was special — it hardcodes
`.app=="Zen"` as its browser predicate and duplicates the arrangement logic. Once
no browser is special, arranging desk 3 and arranging desk 4 are the same
operation:

- `place_desk(space)` — the shared body (resolve slots → `layout_correct` check →
  `arrange` → stray sweep → conditional `--balance`).
- `place_desks(trigger)` — loops `place_desk` over the managed desks. Replaces
  `place_editors`; the `place` signal dispatch renames with it.
- `layout_correct(space)` loses its browser-predicate parameter — it always uses
  `browser_sel` with priority ordering.

`desk_spaces()` replaces `editor_space()` / `zen_space()`, returning both managed
space indices (docked: 3rd and 4th space of the external display; undocked: 3 and
4). Both are now peers; neither is "the work desk."

## 2. Arrangement shape — unchanged

`arrange()` is not modified. The invariant the user confirmed already holds:

- **Browsers left, editors right, always.**
- Full trio: browser top-left, Ghostty bottom-left, editor filling the right.
- Browser + editor: browser left, editor right.
- Ghostty + editor: Ghostty left, editor right.
- Browser + Ghostty, no editor: browser left, Ghostty right.

This design changes *which windows are on a desk*, never *how they are arranged*.

## 3. Sticky incumbent

State file `/tmp/yabai_slots`, same pattern as the existing `/tmp/yabai_display_sig`:

```
<space>:<role>:<window_id>
```

Roles: `editor`, `browser`. **Ghostty is not sticky** — it is the filler window and
resolves as oldest-on-space, as today. (Flagged: revisit if the user starts moving
Ghostty deliberately.)

Rules:

- The recorded incumbent keeps the slot as long as it still exists **and** is still
  on that space. A newly opened window can never take a held slot.
- The slot is vacated when the incumbent closes or leaves the desk.
- **Election** (vacant slot only), in order: the focused window if it is a
  candidate on that desk → position (rightmost for editor, leftmost for browser) →
  oldest window id as final tiebreak.
- Entries whose window id no longer exists are pruned on read.
- The file is lost on reboot. That is fine — every slot is simply vacant and
  elections rebuild it.

## 4. Desk swap

The state file already records *which desk each slot holder belongs to*, so it is
also the origin record. No drag tracking or move history is needed.

Reconciliation, run on every `place` trigger:

```
for each managed desk S, for role in editor, browser:
    inc = state[S][role]
    if inc is gone            -> clear slot
    if inc is on another desk -> clear S's slot (its arrival is handled at that desk)

for each managed desk S, for role in editor, browser:
    if slot vacant -> elect
    else if a candidate C on S is recorded as managed desk D's slot holder (D != S):
        # C was dragged from D onto S
        move incumbent -> D
        state[D][role] = incumbent
        state[S][role] = C
```

Moving the incumbent to `D` leaves `D`'s slot already assigned in the same write,
so the next reconciliation pass sees a consistent state and does nothing. **No swap
loop.**

This covers the reported bug directly: drag Chrome onto desk 4 where Zen holds the
browser slot, and Zen moves to desk 3 rather than being left homeless.

### Trigger — RESOLVED 2026-08-11

**`window_moved` is not usable.** Verified live: it does not fire for a
`yabai -m window --space` move at all, and when it does fire during a drag the
window is still on its old space, so a desk-change test sees nothing. Every swap
observed in testing was resolved by **`space_changed`**, exactly as the fallback
below assumed. A Mission Control drag lands you on the destination desk, so the
swap resolves as you arrive and reads as instant.

The `window_moved` signal is still registered, gated by `on_moved` (one query,
bails unless the desk actually changed), in case yabai's behaviour changes. The
known gap: moving a window *onto the desk you are already on* fires nothing, so
it waits for the next signal.

### Original trigger analysis (superseded by the above)

`space_changed`, `window_created` and `window_destroyed` fire reliably (the current
config depends on them). **It is not established that yabai fires a usable signal
when a window is dragged across spaces via Mission Control.**

The design therefore does not depend on one: reconciliation runs on every existing
`place` trigger. A Mission Control drag normally leaves the user on the destination
desk, which fires `space_changed`, so the swap should feel immediate.

**Spike required (first task in the plan):** with yabai running, drag a window
across spaces and watch `/tmp/yabai.log` for `window_moved` (and whether
`space_changed` fires). If a reliable signal exists, add it as an extra trigger for
lower latency. If not, the reconciliation fallback stands and the known cost is that
a drag performed *without* changing desks does not resolve until the next signal.

### No origin desk — and the drag/open distinction

The original §7 scenarios 3 and 4 contradicted each other: 3 required a newly
opened second editor NOT to take a held slot, 4 required an arriving editor with
no origin TO take it. Both cannot hold. **Resolved during implementation by
splitting on whether the window has an origin at all:**

| Window | Meaning | Slot |
| --- | --- | --- |
| Seen on another desk before | **Drag** — deliberate | Newcomer takes it |
| Never seen | **Fresh open** — incidental | Incumbent keeps it |

A drag from a *managed* desk swaps (§4). A drag from an *unmanaged* space has
nowhere to send the incumbent, so — **decision (user, 2026-08-11)** — the newcomer
takes the slot and the incumbent tiles underneath. The user's newest deliberate
action wins; nothing is moved off a desk the user did not move it from.

This is why `SEEN_FILE` exists as a separate record: the slot file cannot supply an
origin for a window that never held a slot.

This requires relaxing `adopt()`'s guard. Today it skips **all** editors:

```sh
case " $EDITOR_APPS Ghostty $ZEN_APP " in *" $app "*) return 0 ;; esac
```

It must instead skip only *the desk's current slot holders*, so a non-slot editor
tiles in place rather than sitting unmanaged. This is the one part of the design
that adds logic rather than deleting it.

## 5. Deletions

All config-initiated cross-desk moves go:

| Removed | Location |
| --- | --- |
| Browser drag to work desk | `place_editors()` — `browser` in the `--space` loop |
| `place_zen()` Zen exile | whole function + call sites |
| Editor deport | `place_editors()` — `eds_on \| tail -n +2` loop |
| Single-editor adoption | `place_editors()` — `[ "$(… grep -c .)" = 1 ] && ed=$all` |
| Laptop-only force-moves | `place_editors()` — `move_browsers 3; move_editors 4; move Ghostty 5` |
| `move()`, `move_browsers()`, `move_editors()` | unused after the above |

The app-wide `move*` helpers go because nothing moves windows *by app* any more.
The swap in §4 still moves a single window across desks with a direct
`yabai -m window <id> --space <D>` — that is the user's own action taking effect,
not the config relocating windows on its own initiative.

**Laptop-only path — decided without asking, flag on review.** Undocked, the
current code force-assigns browsers→3, editors→4, Ghostty→5. That is cross-desk
dragging and contradicts the core rule, so it is replaced by the same
`place_desks` loop over spaces 3 and 4. Consistency at the cost of losing automatic
consolidation when undocked. Say so if the undocked behaviour is load-bearing.

## 6. Cold boot

Nothing re-herds windows after a reboot; `place_desks` tiles whatever it finds.
Reliable cold-boot placement is delegated to **Dock → right-click app → Options →
Assign To**, which is already how this config handles desk assignment for
everything else:

```sh
# App->desktop assignment is left to macOS (Dock → Assign To).
```

Browsers become consistent with that rather than an exception to it.

## 7. Verification

No test harness exists for this config; verification is manual against
`/tmp/yabai.log`, matching how previous yabai specs in this directory were
validated. Each scenario: perform the action, then confirm the log line and the
resulting layout.

1. **Reported bug** — Chrome + VS Code on desk 4, Zed on desk 3. Trigger a signal.
   Chrome stays on desk 4. *(fails today)*
2. **Swap** — drag VS Code from desk 4 onto desk 3 where Zed holds the slot. Zed
   moves to desk 4; VS Code takes desk 3's slot.
3. **No hijack** — open a second VS Code window on a desk with a held editor slot.
   The incumbent keeps the slot; the newcomer tiles beneath it. *(never seen =
   fresh open)*
4. **No origin** — drag an editor in from an unmanaged space onto an occupied
   desk. Newcomer takes the slot, incumbent tiles beneath. *(seen elsewhere =
   drag)*
5. **Two desks, one editor each** — one editor per desk with a browser each.
   Neither is moved. Close one; the survivor stays on its own desk. *(rule 5 fails
   today via single-editor adoption)*
6. **Shape** — every scenario above ends with browsers left, editors right.
7. **Idempotence** — repeat triggers on a correct layout produce
   `trio correct … skip rebuild` and no window movement.
8. **Undocked** — unplug the external display; desks 3 and 4 are arranged from
   their contents, nothing is force-consolidated.

## 8. As built — rules the design did not anticipate

Every item here was found by running it live on 2026-08-11, undocked. Each one
produced visible window bouncing before it was fixed.

**Origins must be consumed the instant they are acted on.** The design wrote the
seen-record once, at the end of `place_desks`. But a swap moves a window, which
fires its own signals, which starts a *second* `place_desks` before the first
reaches `seen_write` — and that second run reads the stale origin and swaps the
window straight back, forever. `seen_set` now rewrites both windows' records
inside the swap itself.

**Placement is serialized** under `/tmp/yabai_place.lock` (with a one-minute stale
guard). Signals arrive in bursts and two concurrent runs interleave their
read-modify-write of the slot and seen files. Skipping is safe — the run holding
the lock reaches the same final state.

**One slot change per desk/role per reconcile pass**, and each candidate is
re-verified as still being on the desk before it is acted on. The candidate list
is captured before any swap; combined with the origin rewrite above, the loop
would otherwise read the outgoing incumbent as a fresh arrival and swap it back
within a single pass. Measured before the fix: **five swaps on one cross-desk
move.** After: one.

**`warp_to` never warps across spaces.** `--warp` relocates the window to the
target's space, so a stale or off-desk target silently drags a window to another
desk — the exact thing this design forbids. It now bails. Hit for real in testing,
where a stale id pulled Chrome off its desk.

**`warp_to` skips the warp on a two-window desk.** The warp exists only to make
two windows siblings, which on a two-window desk they already are; issuing it
anyway just makes them visibly jump before the repair puts them back. Browser +
editor is the normal desk, so this is the common case. Worst case drops from three
visible repositions to one. The settle delay now runs only after an operation
actually moved something.

**`adopt` bails when the window is already parked under the editor.** Without it,
the desk sweep re-warped a correctly placed window on every single signal — the
old app-based editor guard had been masking this.

### SIP constraint worth knowing

SIP is enabled and the scripting addition does not load, so `--toggle split` and
`--swap` **silently do nothing on a desk that is not currently visible**. `--warp`
is tree-only and works regardless. Consequence: shape repairs only take effect on
the desk you are looking at, which is why all repositioning is witnessed. It also
means desk state can only be verified while that desk is focused — relevant to
anyone testing this later.

## Out of scope

- `skhdrc` keybindings.
- Space 2's `float` chaos zone.
- The `arrange()` / `warp_to()` geometry repair internals.
- Sticky slots for Ghostty.
