# yabai Editor Array + Stray Adoption Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Define the editor app set once (`EDITOR_APPS`) and make any stray window opening on the editor space tile under the editor, live.

**Architecture:** Everything lives in `mac/yabai/yabairc` (single-file config, symlinked so edits are live; signals need a yabai restart to re-register). `EDITOR_APPS` generates the existing `editor_sel` jq predicate plus a new `EDITOR_RE` signal regex. A new `adopt` dispatch command, fired by a no-app-filter `window_created` signal, warps qualifying strays under the first editor window.

**Tech Stack:** POSIX sh, jq, yabai 7.1.25 (SIP-on: `window --space`/`--warp` work; `space --focus` does not).

## Global Constraints

- POSIX sh only (`#!/usr/bin/env sh`) — no bash arrays; `EDITOR_APPS` is a space-separated word list.
- `EDITOR_APPS="Zed Code"` — PhpStorm intentionally excluded (dropped 2026-07-06).
- Space 2 must never be touched by any window logic (float/chat space).
- No `sleep`-based fixes; everything must work SIP-on (no scripting addition).
- Log to `/tmp/yabai.log` via the existing `log()` helper.
- There is no shell test framework in this repo; each task verifies via `sh -n` plus live yabai commands with expected output.

---

### Task 1: `EDITOR_APPS` array drives `editor_sel` and signal regex

**Files:**
- Modify: `mac/yabai/yabairc:30-33` (editor_sel definition)
- Modify: `mac/yabai/yabairc:237-240` (editor signal registrations)

**Interfaces:**
- Consumes: nothing new.
- Produces: `EDITOR_APPS` (space-separated app names, e.g. `"Zed Code"`), `editor_sel` (jq predicate string, unchanged shape: `(.app=="Zed" or .app=="Code")`), `EDITOR_RE` (regex string `^(Zed|Code)$`). Task 2's `adopt` uses `EDITOR_APPS`; existing helpers keep using `editor_sel`.

- [ ] **Step 1: Replace the hand-written `editor_sel` with generated form**

In `mac/yabai/yabairc`, replace:

```sh
# The editor set: Zed and VS Code ("Code"). Both are treated interchangeably as
# "the editor" — whichever are open share the editor slot/layout. This jq
# predicate is the single source of truth for "is this window an editor".
editor_sel='(.app=="Zed" or .app=="Code")'
```

with:

```sh
# The editor set — whichever of these are open share the editor slot/layout.
# THE one list to edit when editors change; editor_sel (jq predicate) and
# EDITOR_RE (signal regex) are generated from it.
EDITOR_APPS="Zed Code"
editor_sel=""
for a in $EDITOR_APPS; do editor_sel="$editor_sel${editor_sel:+ or }.app==\"$a\""; done
editor_sel="($editor_sel)"
EDITOR_RE="^($(echo "$EDITOR_APPS" | tr ' ' '|'))\$"
```

Note: `EDITOR_RE` is built inside double quotes, so the trailing `$` anchor needs the backslash shown to survive as a literal `$`.

- [ ] **Step 2: Point the editor signals at `EDITOR_RE`**

Replace:

```sh
yabai -m signal --add event=window_destroyed app="^(Zed|Code)$" action="\$HOME/Code/dotfiles/mac/yabai/yabairc place"
yabai -m signal --add event=window_created app="^Zen$"          action="\$HOME/Code/dotfiles/mac/yabai/yabairc place"
yabai -m signal --add event=window_created app="^(Zed|Code)$"   action="\$HOME/Code/dotfiles/mac/yabai/yabairc place"
yabai -m signal --add event=window_created app="^Ghostty$"      action="\$HOME/Code/dotfiles/mac/yabai/yabairc place"
```

with:

```sh
yabai -m signal --add event=window_destroyed app="$EDITOR_RE" action="\$HOME/Code/dotfiles/mac/yabai/yabairc place"
yabai -m signal --add event=window_created app="^Zen$"        action="\$HOME/Code/dotfiles/mac/yabai/yabairc place"
yabai -m signal --add event=window_created app="$EDITOR_RE"   action="\$HOME/Code/dotfiles/mac/yabai/yabairc place"
yabai -m signal --add event=window_created app="^Ghostty$"    action="\$HOME/Code/dotfiles/mac/yabai/yabairc place"
```

- [ ] **Step 3: Verify syntax and generated values**

Run:

```sh
sh -n "$HOME/Code/dotfiles/mac/yabai/yabairc" && echo OK
sh -c 'EDITOR_APPS="Zed Code"; editor_sel=""; for a in $EDITOR_APPS; do editor_sel="$editor_sel${editor_sel:+ or }.app==\"$a\""; done; editor_sel="($editor_sel)"; EDITOR_RE="^($(echo "$EDITOR_APPS" | tr " " "|"))\$"; echo "$editor_sel"; echo "$EDITOR_RE"'
```

Expected output:

```
OK
(.app=="Zed" or .app=="Code")
^(Zed|Code)$
```

- [ ] **Step 4: Restart yabai and confirm signals**

Run:

```sh
yabai --restart-service && sleep 3
yabai -m signal --list | jq -r '.[]|select(.app|test("Zed"))|"\(.event) \(.app)"'
"$HOME/Code/dotfiles/mac/yabai/yabairc" place array-test
tail -3 /tmp/yabai.log
```

Expected: `window_created ^(Zed|Code)$` and `window_destroyed ^(Zed|Code)$` listed; log shows a normal `place(array-test)` line (moved/skip), no errors.

- [ ] **Step 5: Commit**

```sh
git add mac/yabai/yabairc
git commit --only mac/yabai/yabairc -m "yabai: generate editor predicate + signal regex from EDITOR_APPS list"
```

### Task 2: `editor_space()` helper + `adopt` stray handler

**Files:**
- Modify: `mac/yabai/yabairc` — add `external_idx()`/`editor_space()` helpers after `win_id()`; refactor `place_editors` to use them; add `adopt()`; add `adopt` dispatch case; add no-filter `window_created` signal.

**Interfaces:**
- Consumes: `EDITOR_APPS`, `editor_ids()`, `win_id()`, `log()`, `LAPTOP_W`/`LAPTOP_H` (all existing after Task 1).
- Produces: `external_idx()` → echoes external display index or nothing; `editor_space()` → echoes editor space index (3rd space of external display, or `4` laptop-only) or nothing; `adopt <window-id>` → warps a qualifying stray under the first editor window; dispatch `yabairc adopt <id>`.

- [ ] **Step 1: Add the helpers and `adopt` function**

Insert after the `win_id()` function (currently ending around `mac/yabai/yabairc:50`):

```sh
external_idx() {  # index of the non-laptop display, empty when undocked
  yabai -m query --displays 2>/dev/null \
    | jq -r --argjson w "$LAPTOP_W" --argjson h "$LAPTOP_H" \
      '.[]|select(.frame.w!=$w or .frame.h!=$h)|.index' | head -1
}

editor_space() {  # space where editors live: 3rd space of the external display
                  # when docked, space 4 laptop-only
  ext=$(external_idx)
  [ -z "$ext" ] && { echo 4; return; }
  yabai -m query --spaces --display "$ext" 2>/dev/null | jq -r '.[2].index // empty'
}

adopt() {  # window_created (any app): tuck a stray under the editor on the
           # editor space. Warp is tree-only, so it works SIP-on unfocused.
  id="$1"; [ -n "$id" ] || return 0
  win=$(yabai -m query --windows --window "$id" 2>/dev/null); [ -n "$win" ] || return 0
  app=$(echo "$win" | jq -r '.app')
  case " $EDITOR_APPS Zen Ghostty " in *" $app "*) return 0 ;; esac
  echo "$win" | jq -e '.subrole=="AXStandardWindow" and .title!="Picture-in-Picture" and ."is-floating"==false' >/dev/null || return 0
  target=$(editor_space); [ -n "$target" ] || return 0
  [ "$(echo "$win" | jq -r '.space')" = "$target" ] || return 0
  ed=$(editor_ids | head -1); [ -n "$ed" ] || return 0
  log adopt "adopt: $app ($id) -> under editor $ed on space $target"
  yabai -m window "$ed" --insert south 2>/dev/null
  yabai -m window "$id" --warp "$ed" 2>/dev/null
}
```

- [ ] **Step 2: Refactor `place_editors` onto the helpers (no behavior change)**

Replace the head of `place_editors`:

```sh
place_editors() {
  trigger="${1:-startup}"
  external_idx=$(yabai -m query --displays 2>/dev/null \
    | jq -r --argjson w "$LAPTOP_W" --argjson h "$LAPTOP_H" \
      '.[]|select(.frame.w!=$w or .frame.h!=$h)|.index' | head -1)

  if [ -z "$external_idx" ]; then
    log place "place($trigger): laptop only -> Zen:3 editors:4 Ghostty:5"
    move Zen 3; move_editors 4; move Ghostty 5
    return
  fi

  target=$(yabai -m query --spaces --display "$external_idx" 2>/dev/null | jq -r '.[2].index // empty')
  [ -z "$target" ] && { log place "place($trigger): external present, no 3rd space"; return; }
```

with:

```sh
place_editors() {
  trigger="${1:-startup}"
  if [ -z "$(external_idx)" ]; then
    log place "place($trigger): laptop only -> Zen:3 editors:4 Ghostty:5"
    move Zen 3; move_editors 4; move Ghostty 5
    return
  fi

  target=$(editor_space)
  [ -z "$target" ] && { log place "place($trigger): external present, no 3rd space"; return; }
```

- [ ] **Step 3: Add the dispatch case and signal**

In the dispatch case block:

```sh
case "$1" in
  display-change) on_display_change; exit 0 ;;
  place)          place_editors "${2:-window}"; exit 0 ;;
esac
```

becomes:

```sh
case "$1" in
  display-change) on_display_change; exit 0 ;;
  place)          place_editors "${2:-window}"; exit 0 ;;
  adopt)          adopt "$2"; exit 0 ;;
esac
```

After the `window_created app="^Ghostty$"` signal line, add:

```sh
yabai -m signal --add event=window_created action="\$HOME/Code/dotfiles/mac/yabai/yabairc adopt \$YABAI_WINDOW_ID"
```

(`$YABAI_WINDOW_ID` is set in the signal's environment by yabai at fire time — both `\$` escapes are required so neither expands at registration.)

- [ ] **Step 4: Verify syntax, restart, confirm signal**

Run:

```sh
sh -n "$HOME/Code/dotfiles/mac/yabai/yabairc" && echo OK
yabai --restart-service && sleep 3
yabai -m signal --list | jq -r '.[]|select(.action|test("adopt"))|"\(.event) app=\(.app)"'
```

Expected: `OK`, then `window_created app=` (empty app filter).

- [ ] **Step 5: Live test — stray on the editor space lands under the editor**

With an editor open on the editor space (check `"$HOME/Code/dotfiles/mac/yabai/yabairc" place` ran and note the space, normally 3 docked):

```sh
open -na TextEdit && sleep 2
yabai -m query --windows | jq -r '.[]|select(.app=="TextEdit" or .app=="Code" or .app=="Zed")|"\(.app) space=\(.space) x=\(.frame.x|floor) y=\(.frame.y|floor)"'
tail -2 /tmp/yabai.log
```

Expected: TextEdit on the editor space with `x` equal to the editor's `x` and `y` greater than the editor's `y` (right column, under the editor); log shows `adopt: TextEdit (...) -> under editor ...`. Note: this only applies if TextEdit opened on the editor space (macOS opens apps on the focused space) — run the test while the editor space is focused. Then quit TextEdit.

- [ ] **Step 6: Live test — non-editor space untouched**

Focus a different space (e.g. `^1`), then:

```sh
open -na TextEdit && sleep 2
yabai -m query --windows | jq -r '.[]|select(.app=="TextEdit")|"space=\(.space)"'
tail -1 /tmp/yabai.log
```

Expected: TextEdit stays on the focused space; NO new `adopt:` line in the log. Quit TextEdit.

- [ ] **Step 7: Commit**

```sh
git add mac/yabai/yabairc
git commit --only mac/yabai/yabairc -m "yabai: adopt stray windows under the editor on the editor space"
```
