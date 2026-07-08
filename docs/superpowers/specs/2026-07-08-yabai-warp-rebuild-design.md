# yabai: warp-based layout rebuild (SIP-on capable)

Date: 2026-07-08 · Scope: `mac/yabai/yabairc` only · Follows: 2026-07-08-yabai-editor-array-stray-adoption-design.md

## Goal

Replace the SA-gated float/reinsert layout rebuild in `place_editors` with a warp-based build that runs identically in both SIP modes, and sweep pre-existing strays under the editor on every place. Deletes the "SIP-on — skipping layout rebuild" limitation.

## Doc-verified semantics (yabai v7.1.25, man page + source)

- `window --warp <target>` honors an insertion point armed on the target via `window <target> --insert <dir>`; without one it falls back to nearest-area heuristics. Arm-then-warp is deterministic.
- The insertion point is **consumed on successful warp** (cleared in `view_add_window_node_with_insertion_point`).
- On **failed** warp the insertion point stays armed, is not queryable, and re-issuing the same `--insert <dir>` toggles it **off** (documented undo behavior). Every warp site therefore uses: arm → warp → on failure, re-issue same `--insert` to disarm.
- `window --warp/--swap/--insert/--toggle float` carry no SIP caveat in the man page (unlike `space --swap`/`space --display`). Same-space warps verified live SIP-on on this machine with the target space focused; **must additionally verify with the target space unfocused** (see Testing).

## Design

### 1. Warp pair helper

```sh
warp_to() {  # arm $2's insertion point toward $3, warp $1 onto $2; disarm on failure
  yabai -m window "$2" --insert "$3" 2>/dev/null
  yabai -m window "$1" --warp "$2" 2>/dev/null && return 0
  yabai -m window "$2" --insert "$3" 2>/dev/null   # same-dir --insert toggles OFF (documented)
  return 1
}
```

### 2. Rebuild in `place_editors` (replaces the SA-gated float/reinsert block)

After the existing moves to `$target` and the `external_correct` skip-check:

- Drop `yabai -m space --focus "$target"` and the `HAS_SA != 1` early return entirely.
- Ensure `$ed`, `$zen`, `$gho` are tiled (`ensure_tiled`, existing helper; `ensure_float` becomes unused and is deleted).
- Editor open: `warp_to "$zen" "$ed" west` (Zen left, editor right), then `warp_to "$gho" "$zen" south` (Ghostty under Zen).
- No editor: `warp_to "$gho" "$zen" east` (Zen | Ghostty side by side).
- `HAS_SA` remains only for `sudo yabai --load-sa`, the `dock_did_restart` signal, and the startup `space --focus 3`.

### 3. Stray sweep

At the end of `place_editors` (external path, editor open, after the rebuild — and also when `external_correct` short-circuits, so a correct trio with misplaced strays still gets cleaned):

```sh
yabai -m query --windows --space "$target" 2>/dev/null \
  | jq -r '.[]|select(.subrole=="AXStandardWindow" and ."is-floating"==false)|.id' \
  | while read -r sid; do adopt "$sid"; done
```

`adopt` already carries every guard (editor/Zen/Ghostty/PiP exclusion, space check, no-editor bail), so the sweep is pure reuse. Restructure `place_editors`'s skip path from `return` to fall through to the sweep. `adopt`'s own warp also switches to `warp_to`.

Sweep ordering: strays warp onto `$ed` south one at a time; later strays split the region further (same as live adoption today).

### 4. Unchanged

Triggers/signals, `external_correct` trio check, laptop-only path, space-2 immunity (all actions remain scoped to `$target` = `editor_space()`), `move`/`move_editors` moves.

## Expected line delta

Net negative or ~flat: deletes the SIP-on early return + `space --focus` + `ensure_float` + the float-everything dance; adds `warp_to` (6 lines) and the sweep loop (3 lines).

## Testing

- `sh -n` syntax check.
- Live, editor space focused: scramble the trio (swap Zen/Ghostty, drop a stray on the space), run `yabairc place test` → trio restored (Zen TL, Ghostty BL, editor TR), stray under editor, `adopt:` log lines present.
- Live, editor space NOT focused (macOS-native switch to another space): repeat the scramble+place → same result. This is the SIP-on-unfocused proof the docs can't give.
- Negative: window on another space untouched; space 2 untouched.
- Failed-warp disarm path: not directly testable live (needs a mid-flight window close); verified by code inspection against the documented toggle semantics.
