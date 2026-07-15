# yabai: browser array (top-left slot)

Date: 2026-07-15 · Scope: `mac/yabai/yabairc` only

## Problem

The placement model hard-codes **Zen** as the sole top-left window of the trio.
When the top-left browser is anything else (Chrome, Safari, Arc), or Zen simply
isn't running:

1. `external_correct()` requires `$zen`, so it reports the layout WRONG even when
   it's exactly what the user wants. Every `place` trigger (any editor / browser /
   Ghostty window created or destroyed) then does a destructive rebuild.
2. `place_editors()` only ever positions Zen, so a non-Zen browser has no slot.
3. The browser is treated purely as an `adopt` stray and yanked south under the
   editor.

Net effect: during normal window open/close activity the layout is constantly
recomputed and fights the user's arrangement. Verified live 2026-07-15 —
`external_correct` returned "needs zen+gho" for a Chrome-TL / Ghostty-BL / Code-R
layout the user confirmed was correct.

## Goal

Generalize the `Zen` role to "the browser" — the first open browser window among a
`BROWSER_APPS` list — exactly mirroring how `EDITOR_APPS` defines the editor set.
One browser occupies the top-left slot at a time ("single browser only").

## 1. Browser array

Top of `yabairc`, beside `EDITOR_APPS`:

```sh
BROWSER_APPS   # "Zen", "Google Chrome", "Safari", "Arc"
```

Generated from it (same shape as the editor artifacts):

- `browser_sel` — jq predicate `(.app=="Zen" or .app=="Google Chrome" or …)`.
- `BROWSER_RE` — signal regex `^(Zen|Google Chrome|Safari|Arc)$`.

**Delimiter caveat:** `EDITOR_APPS="Zed Code"` is space-split because both names are
single words. `Google Chrome` contains a space, so `BROWSER_APPS` must use a
delimiter that survives multi-word names (newline-delimited list iterated with
`while IFS= read -r`, or an explicit non-space separator). The generated
`browser_sel` / `BROWSER_RE` are unaffected — a literal space inside a jq string or
a regex alternation is fine.

## 2. `browser_id()` helper

New helper mirroring `win_id`:

```
first window where browser_sel AND subrole=="AXStandardWindow"
  AND title!="Picture-in-Picture", in query order
```

Returns the single top-left slot occupant. Replaces every current `win_id Zen`
call inside `place_editors` (and any other Zen-specific lookup).

## 3. `external_correct()` — the core fix

Replace the hard-coded Zen selector:

```
($w|map(select(.app=="Zen"))|first) as $zen
```

with the browser selector:

```
($w|map(select(<browser_sel>))|first) as $browser
```

and rename `$zen` → `$browser` throughout its geometry checks. Semantics are
identical (browser top-left above Ghostty; editor to the right) — only the set of
apps that can fill the browser role widens. This is what stops the constant
rebuilds: with any browser in the slot, the trio is recognized as correct and
`place` skips the rebuild.

## 4. `place_editors()`

- `zen=$(win_id Zen)` → `browser=$(browser_id)`; the browser warps west of the
  editor exactly as Zen did (`warp_to "$browser" "$ed" west`, and Ghostty south of
  `${browser:-$ed}`).
- Laptop-only branch: `move Zen 3` generalizes to move browser windows to space 3
  (via a `move`-style loop over `browser_sel`). Editors → 4, Ghostty → 5 unchanged.
- The trailing stray sweep is unchanged in structure (see §5 for how adopt now
  treats browsers).

## 5. `adopt()`

Today adopt bails when `app` is in `EDITOR_APPS` or is `Zen`/`Ghostty` (trio
members with their own placement). Under the new model:

- The **slot browser** (the window whose id == `browser_id`) is excluded from
  adoption — it's positioned by `place_editors`.
- Ghostty and all editor apps remain excluded by app.
- A **second** browser window (id != `browser_id`) is NOT excluded and falls
  through to being adopted under the editor — the explicit "single browser only"
  behavior chosen in brainstorming.

**Delimiter caveat:** the current guard is a space-delimited membership test
(`case " $EDITOR_APPS Zen Ghostty " in *" $app "*`). That breaks on multi-word app
names, so the browser exclusion is expressed as an id comparison against
`browser_id` rather than an app-name membership test.

## 6. Signals

The existing browser placement signal:

```sh
yabai -m signal --add event=window_created app="^Zen$" action="… place"
```

becomes `app="$BROWSER_RE"`, so opening Chrome / Safari / Arc rebuilds the trio
just like opening Zen. The editor and Ghostty signals are unchanged.

## Out of scope / unchanged

- Trio geometry (browser-TL / Ghostty-BL / editor-R), warp/verify/repair machinery,
  `--balance`, space 2 float layout, PiP handling, SIP/SA gating.
- Multi-browser slot-sharing (rejected — "single browser only").
- `LAPTOP_W`/`LAPTOP_H` display-signature values (a separate latent concern: the
  laptop currently reports 3200×1800, not the coded 2056×1329, so the "external
  present" path is active single-display — not touched here).

## Success criteria

- With Chrome (or Safari/Arc) in the top-left slot and no Zen running,
  `external_correct` reports the trio correct → `place` triggers log
  "trio correct … skip rebuild" instead of rebuilding.
- Opening/closing editor, browser, or Ghostty windows no longer disturbs a
  correct browser-TL / Ghostty-BL / editor-R arrangement.
- The slot browser is never adopted south under the editor.
