---
name: project-yabai-browser-left
description: yabairc is one invariant now (browser owns the left, spaces 3+); its no-arg path is the full config load, so never invoke the file incidentally
metadata:
  type: project
---

**2026-08-25 — yabairc collapsed from 695 to 444 lines around a single rule:** on
every space from index 3 up, the leftmost browser must be **strictly** left of
every non-browser. No browser on the space, or nothing but browsers, means no
action. The right-hand side is never constrained. Design and rationale:
`docs/superpowers/specs/2026-08-25-browser-left-invariant-design.md`.

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

**Two browsers splitting evenly needed no code.** `split_type auto` splits a
container vertically only while it is wider than tall: two windows on the
3200x1800 Studio Display go side by side, and the 1583x1778 right half of a
three-window desk stacks. Forcing `split_type vertical` would break the second
case into three narrow columns. Leave it on `auto`.

**Testing this must not drive live windows.** Moving real windows to verify the
rule disrupts whoever is using the machine — Karl said so directly, mid-session.
The invariant's jq is exercised by 18 fixtures instead, with the program extracted
straight out of `yabairc` so the test cannot drift. `warp_to` has its own
regression harness described in [[project-yabai-ax-loss]] (also not in the repo).

Unverified: whether `window_moved` actually fires on a cross-space move.
`space_changed` covers the case regardless, so the `moved` handler is only a
lower-latency duplicate.

See [[project-yabai-ax-loss]], [[project-yabai-browser-incremental]],
[[project-yabai-insert-parity]], [[feedback-yabai-space2]],
[[feedback-yabai-display-events]], [[feedback-no-sleep]].
