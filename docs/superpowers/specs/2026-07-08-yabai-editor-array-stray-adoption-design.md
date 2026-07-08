# yabai: editor array + stray-window adoption

Date: 2026-07-08 · Scope: `mac/yabai/yabairc` only

## Goal

1. Define the "editor" app set in exactly one place.
2. Any other window opening on the editor space tiles under the editor, live.

## 1. Editor array

Top of `yabairc`:

```sh
EDITOR_APPS="Zed Code"   # the editor set — edit this list only
```

Generated from it:

- `editor_sel` — jq predicate `(.app=="Zed" or .app=="Code")`, built by loop. All existing consumers (`move_editors`, `editor_ids`, `external_correct`, `place_editors`) already use it; they don't change.
- `EDITOR_RE` — `^(Zed|Code)$`, used by the two editor signal registrations (`window_created`, `window_destroyed`).

PhpStorm intentionally excluded (dropped 2026-07-06). Adding an editor later is a one-word edit.

## 2. Stray adoption

New helper `editor_space()` — returns the editor target space index: 3rd space of the external display when docked, space 4 laptop-only. `place_editors` refactors to use it (same logic, no behavior change).

New function `adopt <window-id>`, dispatched via a new no-app-filter signal:

```sh
yabai -m signal --add event=window_created action="... yabairc adopt \$YABAI_WINDOW_ID"
```

`adopt` bails unless ALL of:

- window is on `editor_space()` (space 2 and everything else untouched)
- subrole `AXStandardWindow`, title != `Picture-in-Picture`, not floating
- app is not Zen, Ghostty, or in `EDITOR_APPS` (those have their own placement)
- an editor window is open (else stray tiles normally)

Then: `yabai -m window $ed --insert south && yabai -m window $id --warp $ed` — stray lands under the editor in the right column. Warp is tree-only, so it works SIP-on without space focus. Multiple strays keep splitting under the editor.

Rejected alternative: pre-priming the insertion point on the editor (consumed on use, global — fragile).

## Testing

- `sh -n` syntax check.
- Live: open a non-editor window on the editor space → lands under Code/Zed; open one on another space → untouched; close all editors, open stray on editor space → tiles normally.
- Confirm signals via `yabai -m signal --list`.
