---
name: project-yabai-browser-left
description: yabairc is one invariant now (browser owns the left, spaces 3+); its no-arg path is the full config load, so never invoke the file incidentally
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

Unverified: whether `window_moved` actually fires on a cross-space move.
`space_changed` covers the case regardless, so the `moved` handler is only a
lower-latency duplicate.

See [[project-yabai-ax-loss]], [[project-yabai-browser-incremental]],
[[project-yabai-insert-parity]], [[feedback-yabai-space2]],
[[feedback-yabai-display-events]], [[feedback-no-sleep]].
