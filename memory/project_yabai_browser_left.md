---
name: project-yabai-browser-left
description: yabairc is one invariant (browser owns the left column, spaces 3+; every browser window in it since 2026-09-11); window_origin_display=focused beats an app's saved display; its no-arg path is the full config load, so never invoke the file incidentally
metadata:
  type: project
---

**2026-08-25 — yabairc collapsed from 695 to 444 lines around a single rule:** on
every space from index 3 up, **the browser owns the TOP-LEFT** — the topmost
window of the leftmost column is a browser. No browser on the space means no
action; the right-hand side is never constrained. Design and rationale:
`docs/superpowers/specs/2026-08-25-browser-left-invariant-design.md`.

**Two weaker rules were tried first and both shipped a layout Karl rejected on
sight. Do not re-derive either.**
- *"A browser is somewhere in the leftmost column"* (equality on min x) accepts an
  EDITOR on top of the browser in that column.
- *"The leftmost browser is strictly left of every non-browser"* MANUFACTURES
  COLUMNS. Any non-browser landing in the browser's own column is a violation
  whose only repair is warping the browser further west, so browser + terminal +
  editor converges on three equal columns.

**The transferable lesson: a rule's repair is part of the rule.** Strict's only
available move was "add a column", and adding a column can never be the fix for
"something shares my column". Check what a candidate invariant's repair *does*
before adopting the invariant. Today's repair direction comes from the violation:
`north` within the column when a browser is present but not topmost (adds no
column), `west` only when the left column holds no browser, balance-only for the
squeeze guard.

**The trap that cost real damage: `yabairc` with NO argument is the full config
load.** The file is both the config and its own signal-handler dispatcher — a
`case "$1"` handles `place-all`/`place-focused`/`place-one`/`moved`, and anything
else **falls through to the entire load block**: every `yabai -m config`, every
`rule --add`, `rule --apply`, all eight `signal --add` calls, and a placement run.
Calling it incidentally (e.g. an unused `$(...)` inside a diagnostic loop)
re-registers every signal. Seven stray invocations left **8 duplicate
registrations per event**, so every window event spawned 8 handler chains.

Prune duplicates in place, without restarting yabai (which matters when someone is
working):

```sh
yabai -m signal --list \
  | jq -r 'group_by(.event)|map(sort_by(.index)|.[1:])|flatten|map(.index)|sort|reverse|.[]' \
  | while IFS= read -r i; do yabai -m signal --remove "$i"; done
```

Highest index first, because removal renumbers. Note `--signals` is **not** a
`query` domain in yabai 7.1.25 — it is `signal --list`.

**`for i in $list` does not split in this shell.** The Bash tool runs zsh, which
does not word-split unquoted parameter expansions. A loop over a newline-separated
capture silently passes the whole blob as one argument. Use
`printf '%s\n' "$list" | while IFS= read -r i`.

**`split_type auto` decides at INSERTION time, and an explicit `--warp` overrides
it.** auto splits a container vertically only while it is wider than tall, so left
alone it puts two windows side by side on the 3200x1800 Studio Display and stacks
the right half of a three-window desk. But that is what bsp does unattended — it
is NOT a guarantee about the final tree, and reasoning as though it were is what
made the strict rule look safe. Leave it on `auto` regardless: forcing `vertical`
turns a three-window desk into three narrow columns.

**Testing this must not drive live windows.** Moving real windows to verify the
rule disrupts whoever is using the machine — Karl said so directly, mid-session.
The invariant's jq is exercised by 21 fixtures instead, with the program extracted
straight out of `yabairc` so the test cannot drift. `warp_to` has its own
regression harness described in [[project-yabai-ax-loss]] (also not in the repo).

`window_moved` DOES fire on a cross-space move (seen live 2026-09-11, twice per
move), so the `moved` handler is a real lower-latency path, not just a duplicate.

**2026-09-11 — two additions, both from Karl's "browsers never open where I am".**
- **Chrome remembers its display.** Chrome saves `browser.window_placement` per
  profile and restores it on every launch and Cmd+N. Profile 1 held `left:3212`,
  i.e. the laptop screen (display 2, x 3200–5256), so every Chrome window opened
  on space 10 and dragged focus there. Nothing in the dotfiles or macOS did it.
  Fix: `yabai -m config window_origin_display focused` — yabai moves the new
  window to the focused display as it is created. Verified live (`default` ->
  space 10, `focused` -> the space in front of Karl). Zen's saved frames were on
  display 1, so Zen never had this problem.
- **Every browser window is in the left column now, not just one.** A restored
  second Zen window sat bottom-right because only the top-left was constrained.
  New repair direction `south`: a browser outside the left column is warped
  under the top-left browser (adds no column). **Narrowed 2026-09-17 — see
  below; a browser BESIDE the top-left one is fine.** `place_space` runs up to three
  one-repair passes, because the second browser needs a second pass and the
  signals that used to supply it are gated out. Verified live: two Zen windows
  stack at x=12.
- I did drive live windows to verify both (opened/closed test windows on Karl's
  desk, focused Code). Karl was in the loop and asking for it, but the standing
  rule above still applies by default.

**2026-09-17 — `south` was one dimension too broad.** `$bout` selected every
browser outside the leftmost column, so two Zen windows deliberately side by side
read as a violation and got stacked on every arrival at the desk (16 rebuilds in
a day on space 3, each undone by hand). A browser now counts as out of place only
when it is outside the left column **AND below the top row** — level with the
top-left browser means beside it, not stranded. The stranded bottom-right case
the clause was written for still repairs. `e16eaba` did not cause this; it made
it visible, because the repair used to defer to the next arrival.

The fixtures that cover this jq are **still not in the repo** and had to be
rebuilt from scratch to verify the change — second time that cost real work. If
you touch `space_state` again, extract the jq out of `yabairc` and run it against
cases rather than driving live windows.

See [[project-yabai-ax-loss]], [[project-yabai-browser-incremental]],
[[project-yabai-insert-parity]], [[feedback-yabai-space2]],
[[feedback-yabai-display-events]], [[feedback-no-sleep]].
