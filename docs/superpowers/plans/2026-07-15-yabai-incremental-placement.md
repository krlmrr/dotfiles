# yabai Incremental On-Open Placement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On a window opening, place ONLY the new window into its trio slot with a single move, instead of a full teardown-rebuild that reshuffles the whole trio.

**Architecture:** A new `place_one <id>` router (reusing `adopt` for strays) is dispatched by a single catch-all `window_created` signal that replaces the four current ones. `place_editors` (full rebuild) is retained only for `startup`/`display-change`/editor-`window_destroyed`.

**Tech Stack:** POSIX sh, `yabai -m query`/`jq`, macOS LaunchAgent.

## Global Constraints

- Scope is `mac/yabai/yabairc` ONLY.
- `mac/yabai/yabairc` is symlinked (live on edit); signal REGISTRATIONS only take effect on `yabai --restart-service`, but functions invoked via `yabairc <cmd>` run from the current file immediately.
- Only the newly-created window may be repositioned by `place_one`; no other window's frame may change on the open path, and no global `--balance` on that path.
- Anchor rules (cross-role, order-independent for the browser/editor pair):
  slot browser → **west** of editor; editor → **east** of browser; Ghostty → **south** of browser (fallback editor); stray / 2nd browser → `adopt` (south under editor).
- Anchor-absent → do NOT warp (window stays as the anchor for the next open).
- Reuse existing helpers unchanged: `adopt`, `editor_space`, `browser_id`, `editor_ids`, `win_id`, `ensure_tiled`, `warp_to`, and vars `EDITOR_APPS`, `browser_sel`.
- Do not change `external_correct`, trio geometry, space 2 float, PiP handling, SIP/SA gating, or the `window_destroyed` signals.

---

### Task 1: Add `place_one <id>` router + dispatch case

**Files:**
- Modify: `mac/yabai/yabairc` (add `place_one()` after `place_editors()`; add a `place-one)` branch to the dispatch `case`)

**Interfaces:**
- Consumes: `adopt`, `editor_space`, `browser_id`, `editor_ids`, `ensure_tiled`, `warp_to`, `browser_sel`, `EDITOR_APPS`.
- Produces: `place_one <window-id>` — routes one window to its slot; dispatchable via `yabairc place-one <id>`.

- [ ] **Step 1: Add the `place_one()` function** immediately after the `place_editors()` function:

```sh
# ------------------------------------------------- incremental single placement
# window_created (any app): place ONLY the new window ($1) into its trio slot,
# relative to a cross-role anchor, with a single warp — nothing else moves.
# Strays and 2nd browsers fall through to adopt (tuck south under the editor).
# Full-trio rebuilds stay in place_editors (startup/display-change only).
place_one() {
  id="$1"; [ -n "$id" ] || return 0
  win=$(yabai -m query --windows --window "$id" 2>/dev/null); [ -n "$win" ] || return 0
  echo "$win" | jq -e '.subrole=="AXStandardWindow" and .title!="Picture-in-Picture" and ."is-floating"==false' >/dev/null || return 0
  app=$(echo "$win" | jq -r '.app')
  target=$(editor_space); [ -n "$target" ] || return 0

  # Role -> anchor id + warp direction. Empty dir => not a positioned trio
  # member (stray / 2nd browser) -> adopt.
  anchor=""; dir=""
  if echo "$win" | jq -e "$browser_sel" >/dev/null 2>&1 && [ "$id" = "$(browser_id)" ]; then
    anchor=$(editor_ids | head -1); dir=west            # slot browser -> west of editor
  else
    case " $EDITOR_APPS " in
      *" $app "*) anchor=$(browser_id); dir=east ;;      # editor -> east of browser
      *) if [ "$app" = "Ghostty" ]; then                 # ghostty -> south of browser|editor
           anchor=$(browser_id); [ -n "$anchor" ] || anchor=$(editor_ids | head -1); dir=south
         fi ;;
    esac
  fi

  if [ -n "$dir" ]; then
    [ "$(echo "$win" | jq -r '.space')" = "$target" ] || yabai -m window "$id" --space "$target" 2>/dev/null
    ensure_tiled "$id"
    if [ -n "$anchor" ]; then
      log one "place-one: $app $id -> $dir of $anchor"
      warp_to "$id" "$anchor" "$dir"
    else
      log one "place-one: $app $id -> anchor absent, left as anchor"
    fi
  else
    adopt "$id"
  fi
}
```

- [ ] **Step 2: Add the dispatch branch.** In the `case "$1" in` block (near `place)` and `adopt)`), add:

```sh
  place-one)      place_one "$2"; exit 0 ;;
```

- [ ] **Step 3: Syntax check**

Run: `sh -n mac/yabai/yabairc && echo OK`
Expected: `OK`

- [ ] **Step 4: Functional smoke test via direct invocation** (does NOT need a reload — `yabairc place-one` runs the current file). Open a Ghostty window, wait for it to settle, then invoke `place-one` on it and confirm it logs a `[one]` line and lands (Ghostty south of the browser/editor anchor). NOTE: opening the window also triggers the *old* signals (still wired until Task 2), so a `[place]` rebuild may also appear — that's expected here; we're only checking that `place_one` itself runs and routes correctly.

Run:
```sh
before=$(wc -l < /tmp/yabai.log)
open -na Ghostty
for i in $(seq 1 40); do n=$(wc -l < /tmp/yabai.log); [ "$n" -gt "$before" ] && break; sleep 0.25; done
gid=$(yabai -m query --windows | jq -r '[.[]|select(.app=="Ghostty" and .subrole=="AXStandardWindow")]|sort_by(.id)|last|.id')
"$HOME/Code/dotfiles/mac/yabai/yabairc" place-one "$gid"
echo "=== [one] log line(s) ==="; grep '\[one\]' /tmp/yabai.log | tail -3
echo "=== ghostty frame now ==="; yabai -m query --windows --window "$gid" | jq -r '"x=\(.frame.x|floor) y=\(.frame.y|floor) w=\(.frame.w|floor) h=\(.frame.h|floor)"'
# cleanup the test window
yabai -m window "$gid" --close 2>/dev/null && echo "closed test ghostty $gid"
```
Expected: a `[one] place-one: Ghostty <id> -> south of <anchor>` (or `anchor absent`) line appears; no shell errors.

- [ ] **Step 5: Commit**

```bash
git add mac/yabai/yabairc
git commit -m "yabai: add place_one() incremental single-window placement router"
```

---

### Task 2: Collapse the four `window_created` signals into one

**Files:**
- Modify: `mac/yabai/yabairc` (the signal-registration block near the bottom of the load section)

**Interfaces:**
- Consumes: `place_one` (Task 1).
- Produces: one catch-all `window_created` signal firing `place-one $YABAI_WINDOW_ID`.

- [ ] **Step 1: Replace the four `window_created` registrations.** Delete these four lines (the three per-app `place` signals and the catch-all `adopt` signal):

```sh
yabai -m signal --add event=window_created app="$BROWSER_RE"  action="\$HOME/Code/dotfiles/mac/yabai/yabairc place"
yabai -m signal --add event=window_created app="$EDITOR_RE"   action="\$HOME/Code/dotfiles/mac/yabai/yabairc place"
yabai -m signal --add event=window_created app="^Ghostty$"    action="\$HOME/Code/dotfiles/mac/yabai/yabairc place"
yabai -m signal --add event=window_created action="\$HOME/Code/dotfiles/mac/yabai/yabairc adopt \$YABAI_WINDOW_ID"
```

and replace them with this single line:

```sh
yabai -m signal --add event=window_created action="\$HOME/Code/dotfiles/mac/yabai/yabairc place-one \$YABAI_WINDOW_ID"
```

Leave the `window_destroyed app="$BROWSER_RE"`/`"$EDITOR_RE"` and `display_*` signals, and the `window_destroyed → space --balance` signal, UNCHANGED. (Note: the editor `window_destroyed → place` signal stays — closing is out of scope.)

- [ ] **Step 2: Syntax check**

Run: `sh -n mac/yabai/yabairc && echo OK`
Expected: `OK`

- [ ] **Step 3: Static check the signal set.** Confirm exactly one `window_created` registration remains and it calls `place-one`; confirm no `window_created` still calls `place` or `adopt`.

Run:
```sh
grep -n 'event=window_created' mac/yabai/yabairc
```
Expected: exactly ONE line, ending in `place-one \$YABAI_WINDOW_ID`. No `window_created` line contains `yabairc place"` or `yabairc adopt`.

- [ ] **Step 4: Commit**

```bash
git add mac/yabai/yabairc
git commit -m "yabai: single window_created -> place-one signal (replaces 4, fixes double-fire)"
```

---

### Task 3: Live acceptance (reload + measure single-window motion)

**Files:**
- None (verification only).

**Interfaces:**
- Consumes: the full updated config.
- Produces: proof that opening a window moves only that window and fires exactly one handler.

- [ ] **Step 1: Reload yabai** (registers the new single signal), and wait for load to complete (condition-based, not a fixed sleep):

```sh
before=$(wc -l < /tmp/yabai.log)
yabai --restart-service
for i in $(seq 1 40); do n=$(wc -l < /tmp/yabai.log); { [ "$n" -gt "$before" ] && tail -n +$((before+1)) /tmp/yabai.log | grep -q '\[load\] config loaded'; } && break; sleep 0.25; done
tail -n +$((before+1)) /tmp/yabai.log
```
Expected: a fresh `[load] config loaded` block.

- [ ] **Step 2: Snapshot all space-3 window frames BEFORE opening.**

```sh
snap() { yabai -m query --windows | jq -S '[.[]|select(.space==3 and .subrole=="AXStandardWindow")|{id,app,x:(.frame.x|floor),y:(.frame.y|floor),w:(.frame.w|floor),h:(.frame.h|floor)}]'; }
SP=/private/tmp/claude-501/-Users-karlm-Code-dotfiles/6ae1db66-9e6e-461e-bdc8-58ffd9108122/scratchpad
snap > "$SP/before.json"; cat "$SP/before.json"
logbefore=$(wc -l < /tmp/yabai.log)
```

- [ ] **Step 3: Open one window (Ghostty) and wait for placement to log.**

```sh
open -na Ghostty
for i in $(seq 1 40); do n=$(wc -l < /tmp/yabai.log); [ "$n" -gt "$logbefore" ] && break; sleep 0.25; done
echo "=== new log lines ==="; tail -n +$((logbefore+1)) /tmp/yabai.log
```
Expected: exactly ONE `[one] place-one: Ghostty …` line. NO `[place] … rebuild …` line (no full rebuild). No duplicate handler lines.

- [ ] **Step 4: Verify only the new window moved.** Snapshot after, and diff against before by id — every pre-existing id must have an identical frame; only the new Ghostty id is added.

```sh
snap > "$SP/after.json"
echo "=== pre-existing windows whose frame CHANGED (expect none) ==="
jq -n --slurpfile b "$SP/before.json" --slurpfile a "$SP/after.json" '
  ($b[0]) as $B | ($a[0]) as $A
  | [ $B[] | . as $w | ($A[]|select(.id==$w.id)) as $x
      | select($x != null and ($x|del(.app)) != ($w|del(.app))) | {id:$w.id, app:$w.app, before:$w, after:$x} ]'
echo "=== new window(s) added ==="
jq -n --slurpfile b "$SP/before.json" --slurpfile a "$SP/after.json" '
  ($b[0]|map(.id)) as $ids | $a[0][] | select(.id as $i | ($ids|index($i))|not)'
```
Expected: the CHANGED list is empty (`[]`); exactly one new Ghostty window is added. This is the core success criterion — only the new window moved.

- [ ] **Step 5: Clean up the test window.**

```sh
gid=$(jq -n --slurpfile b "$SP/before.json" --slurpfile a "$SP/after.json" '($b[0]|map(.id)) as $ids | ($a[0][]|select(.id as $i|($ids|index($i))|not)|.id)' | head -1)
[ -n "$gid" ] && yabai -m window "$gid" --close 2>/dev/null && echo "closed test window $gid"
```

- [ ] **Step 6 (optional, on user request): tag a release**

```bash
./release <next-version>   # latest: git tag --sort=-v:refname | head -1
```

---

## Notes for the implementer

- Tasks 1-2 do NOT reload yabai; only Task 3 does (one restart, expected for a new feature). Until Task 3, the running process uses the old four signals, but `place_one` is directly invocable via `yabairc place-one <id>` because signal actions re-run the current file.
- Live state is fluid (the user may open/close browsers between steps). In Task 3, if the CHANGED list is non-empty, STOP and return to systematic-debugging — do not patch blindly; a moved pre-existing window means `place_one`/`warp_to` disturbed a neighbor, which is the exact thing this change must not do.
- If opening Ghostty in Task 3 produces a `[place]` rebuild line (not `[one]`), the signal collapse didn't take effect — re-check Task 2 and that the reload succeeded.
