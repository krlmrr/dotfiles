# yabai Warp-Based Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the SA-gated float/reinsert layout rebuild in `place_editors` with a warp-based build that runs in both SIP modes, and sweep pre-existing strays under the editor on every place.

**Architecture:** All in `mac/yabai/yabairc` (single-file POSIX sh config, symlinked — function edits are live, no signal changes in this plan so no yabai restart is strictly required, but restart before live tests to be safe). A `warp_to` helper encodes the doc-verified arm→warp→disarm-on-failure pattern; the rebuild and `adopt` both use it; a sweep loop reuses `adopt` for pre-existing strays.

**Tech Stack:** POSIX sh, jq, yabai v7.1.25 SIP-on (warp/swap/insert/toggle-float are tree-only and work without the scripting addition; `space --focus` does not).

## Global Constraints

- POSIX sh only — no bash arrays, no `local`.
- Space 2 must never be touched; all actions stay scoped to `$target` = the editor space.
- No `sleep`-based fixes (waiting for daemon boot after a restart is fine).
- Log via existing `log()` helper to `/tmp/yabai.log`.
- Insertion-point semantics (doc-verified, yabai v7.1.25): warp honors an armed insertion point on the target; the point is consumed on successful warp; on failed warp it stays armed and is not queryable; re-issuing the same `--insert <dir>` toggles it off. Every warp site must use the arm→warp→disarm-on-failure pattern (`warp_to`).
- `HAS_SA` may remain only for: `sudo yabai --load-sa`, the `dock_did_restart` signal, and the startup `yabai -m space --focus 3`.
- No test framework; verification = `sh -n` + live yabai commands with expected output.

---

### Task 1: `warp_to` helper + warp-based rebuild

**Files:**
- Modify: `mac/yabai/yabairc` — add `warp_to` after `ensure_float`; replace the SA-gated rebuild block in `place_editors`; switch `adopt`'s warp pair to `warp_to`; delete `ensure_float` (unused after this change).

**Interfaces:**
- Consumes: `ensure_tiled`, `external_correct`, `log`, `adopt`, `HAS_SA` (all existing).
- Produces: `warp_to <src-id> <target-id> <dir>` → arms target's insertion point toward dir, warps src onto target, disarms on failure; returns 0 on success. Task 2 relies on `place_editors` keeping the `external_correct` skip as an early `return` (Task 2 restructures it).

- [ ] **Step 1: Add `warp_to` and delete `ensure_float`**

After the `ensure_tiled` line, replace:

```sh
ensure_float() { [ "$(floating "$1")" = "false" ] && yabai -m window "$1" --toggle float 2>/dev/null; return 0; }
```

with:

```sh
warp_to() {  # arm $2's insertion point toward $3, warp $1 onto $2. The point is
             # consumed on success; on failure re-issue the same --insert, which
             # toggles it OFF (documented undo), so nothing stays armed.
  yabai -m window "$2" --insert "$3" 2>/dev/null
  yabai -m window "$1" --warp "$2" 2>/dev/null && return 0
  yabai -m window "$2" --insert "$3" 2>/dev/null
  return 1
}
```

- [ ] **Step 2: Replace the SA-gated rebuild in `place_editors`**

Replace everything from the comment `# The float/reinsert rebuild below needs the target space focused` down to the end of the function's `if/else` build block (the lines below, currently the tail of `place_editors`):

```sh
  # The float/reinsert rebuild below needs the target space focused, which
  # requires the SA. Under SIP-on the editors are already moved (above); skip
  # the layout arrange rather than run it blind on a non-visible space.
  if [ "$HAS_SA" != 1 ]; then
    log place "place($trigger): SIP-on — moved to $target, skipping layout rebuild"
    return
  fi

  # Float-then-reinsert build (avoids --warp ambiguity).
  yabai -m space --focus "$target" 2>/dev/null
  if [ -n "$ed" ]; then
    # Editor open -> stacked: editor base (full-right), Zen west, Ghostty south of Zen.
    log place "place($trigger): rebuild stacked (editor open) — Zen TL / Ghostty BL / editor R"
    ensure_tiled "$ed"
    [ -n "$zen" ] && ensure_float "$zen"
    [ -n "$gho" ] && ensure_float "$gho"
    if [ -n "$zen" ]; then yabai -m window "$ed" --insert west 2>/dev/null; ensure_tiled "$zen"; fi
    if [ -n "$gho" ]; then
      anchor="${zen:-$ed}"
      yabai -m window "$anchor" --insert south 2>/dev/null
      ensure_tiled "$gho"
    fi
  else
    # No editor -> side by side: Zen left (base), Ghostty re-tiles east of it.
    log place "place($trigger): rebuild side-by-side (no editor) — Zen | Ghostty"
    [ -n "$zen" ] && ensure_tiled "$zen"
    if [ -n "$gho" ]; then
      ensure_float "$gho"
      [ -n "$zen" ] && yabai -m window "$zen" --insert east 2>/dev/null
      ensure_tiled "$gho"
    fi
  fi
```

with:

```sh
  # Warp-based rebuild: tree-only ops, no space focus needed — runs in both SIP modes.
  for id in $ed $zen $gho; do ensure_tiled "$id"; done
  if [ -n "$ed" ]; then
    log place "place($trigger): rebuild stacked (editor open) — Zen TL / Ghostty BL / editor R"
    [ -n "$zen" ] && warp_to "$zen" "$ed" west
    [ -n "$gho" ] && warp_to "$gho" "${zen:-$ed}" south
  else
    log place "place($trigger): rebuild side-by-side (no editor) — Zen | Ghostty"
    [ -n "$zen" ] && [ -n "$gho" ] && warp_to "$gho" "$zen" east
  fi
```

(Layout semantics preserved exactly: Zen west of editor, Ghostty south of Zen — or south of the editor when Zen is closed; side-by-side when no editor.)

- [ ] **Step 3: Switch `adopt` to `warp_to`**

In `adopt()`, replace:

```sh
  yabai -m window "$ed" --insert south 2>/dev/null
  yabai -m window "$id" --warp "$ed" 2>/dev/null
```

with:

```sh
  warp_to "$id" "$ed" south
```

- [ ] **Step 4: Verify — syntax + scramble/rebuild live test (editor space focused or not)**

```sh
sh -n "$HOME/Code/dotfiles/mac/yabai/yabairc" && echo OK
grep -c ensure_float "$HOME/Code/dotfiles/mac/yabai/yabairc"
```

Expected: `OK`, then `0` (helper fully removed).

Live (this machine is docked, editor space = 3): scramble the trio by swapping Zen and Ghostty, then run place and confirm restoration:

```sh
ZEN=$(yabai -m query --windows | jq -r '.[]|select(.app=="Zen" and .subrole=="AXStandardWindow")|.id' | head -1)
GHO=$(yabai -m query --windows | jq -r '.[]|select(.app=="Ghostty" and .subrole=="AXStandardWindow")|.id' | head -1)
yabai -m window "$ZEN" --swap "$GHO"
"$HOME/Code/dotfiles/mac/yabai/yabairc" place warp-test
sleep 1
yabai -m query --windows --space 3 | jq -r '.[]|select(."is-floating"==false and .subrole=="AXStandardWindow")|"\(.app) x=\(.frame.x|floor) y=\(.frame.y|floor)"'
tail -3 /tmp/yabai.log
```

Expected: Zen top-left (smallest x, smallest y), Ghostty below Zen (same x, larger y), editor to the right (larger x); log shows `rebuild stacked (editor open)` — NOT the old "SIP-on — skipping" line, which no longer exists.

Record the focused space during the test (`yabai -m query --spaces | jq '.[]|select(."has-focus"==true).index'`). If it was 3, the unfocused variant is still unproven — note that in the report; the controller arranges it (requires the human to switch spaces).

- [ ] **Step 5: Commit**

```sh
git add mac/yabai/yabairc
git commit --only mac/yabai/yabairc -m "yabai: warp-based layout rebuild, works SIP-on (drops float/reinsert + focus)"
```

### Task 2: Stray sweep on every place

**Files:**
- Modify: `mac/yabai/yabairc` — restructure `place_editors`' `external_correct` skip from early-return to fall-through, and append the sweep loop at the end of the external path.

**Interfaces:**
- Consumes: `adopt <id>` (existing — carries all guards: editor/Zen/Ghostty exclusion, PiP/subrole/floating checks, target-space check, no-editor bail), `external_correct`, `log`.
- Produces: no new interfaces; `place_editors` now ends with the sweep.

- [ ] **Step 1: Restructure skip + append sweep**

In `place_editors`, replace:

```sh
  if external_correct "$target"; then
    log place "place($trigger): already correct on space $target — skip"
    return
  fi

  # Warp-based rebuild: tree-only ops, no space focus needed — runs in both SIP modes.
  for id in $ed $zen $gho; do ensure_tiled "$id"; done
  if [ -n "$ed" ]; then
    log place "place($trigger): rebuild stacked (editor open) — Zen TL / Ghostty BL / editor R"
    [ -n "$zen" ] && warp_to "$zen" "$ed" west
    [ -n "$gho" ] && warp_to "$gho" "${zen:-$ed}" south
  else
    log place "place($trigger): rebuild side-by-side (no editor) — Zen | Ghostty"
    [ -n "$zen" ] && [ -n "$gho" ] && warp_to "$gho" "$zen" east
  fi
```

with:

```sh
  if external_correct "$target"; then
    log place "place($trigger): trio correct on space $target — skip rebuild"
  else
    # Warp-based rebuild: tree-only ops, no space focus needed — runs in both SIP modes.
    for id in $ed $zen $gho; do ensure_tiled "$id"; done
    if [ -n "$ed" ]; then
      log place "place($trigger): rebuild stacked (editor open) — Zen TL / Ghostty BL / editor R"
      [ -n "$zen" ] && warp_to "$zen" "$ed" west
      [ -n "$gho" ] && warp_to "$gho" "${zen:-$ed}" south
    else
      log place "place($trigger): rebuild side-by-side (no editor) — Zen | Ghostty"
      [ -n "$zen" ] && [ -n "$gho" ] && warp_to "$gho" "$zen" east
    fi
  fi

  # Sweep pre-existing strays under the editor (adopt carries all the guards,
  # including the no-editor bail, so this is safe when no editor is open).
  yabai -m query --windows --space "$target" 2>/dev/null \
    | jq -r '.[]|select(.subrole=="AXStandardWindow" and ."is-floating"==false)|.id' \
    | while read -r sid; do adopt "$sid"; done
```

- [ ] **Step 2: Verify — syntax + sweep live test (including the skip path)**

```sh
sh -n "$HOME/Code/dotfiles/mac/yabai/yabairc" && echo OK
```

Live sweep test — put a stray somewhere wrong on space 3 without breaking the trio, then place:

```sh
open -na TextEdit; sleep 2
TE=$(yabai -m query --windows | jq -r '.[]|select(.app=="TextEdit" and .subrole=="AXStandardWindow")|.id' | head -1)
yabai -m window "$TE" --space 3 2>/dev/null   # ensure it's on the editor space
ZEN=$(yabai -m query --windows | jq -r '.[]|select(.app=="Zen" and .subrole=="AXStandardWindow")|.id' | head -1)
yabai -m window "$TE" --warp "$ZEN" 2>/dev/null   # shove it into the LEFT column (wrong place)
"$HOME/Code/dotfiles/mac/yabai/yabairc" place sweep-test
sleep 1
yabai -m query --windows --space 3 | jq -r '.[]|select(."is-floating"==false and .subrole=="AXStandardWindow")|"\(.app) x=\(.frame.x|floor) y=\(.frame.y|floor)"'
grep adopt /tmp/yabai.log | tail -2
osascript -e 'tell application "TextEdit" to quit saving no'
```

Expected: TextEdit ends in the RIGHT column (x matches the editor's x-band, y below the editor), an `adopt: TextEdit` log line from the sweep; trio intact. If the trio was already correct the log shows `trio correct … skip rebuild` AND the sweep still ran — that proves the fall-through.

Negative: `yabai -m query --windows --space 2 | jq length` before and after place — identical (space 2 untouched).

- [ ] **Step 3: Commit**

```sh
git add mac/yabai/yabairc
git commit --only mac/yabai/yabairc -m "yabai: sweep pre-existing strays under the editor on every place"
```
