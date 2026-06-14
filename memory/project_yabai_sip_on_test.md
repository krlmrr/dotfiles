---
name: project-yabai-sip-on-test
description: Karl is testing yabai WITHOUT SIP disabled on a macOS 27 beta volume; wants a SIP-on yabairc variant
metadata:
  type: project
---

On 2026-06-09 Karl installed the macOS 27 "Golden Gate" Beta 1 (build 26A5353q) onto a separate APFS volume named "Beta" (M2 Max, main install stays on `Macintosh HD`). Goal there: see how much of the yabai setup works **without disabling SIP** — i.e., with no scripting addition (SA) loaded.

Preferred approach (Karl's idea): make `mac/yabai/yabairc` **self-detecting** — ONE config that branches at runtime on whether the scripting addition is usable, rather than a separate SIP-on variant. Detect via `csrutil status` (no sudo needed): SA-capable if it contains `status: disabled` or `Filesystem Protections: disabled`; else full SIP → tiling-only. In the SA branch: `sudo yabai --load-sa`, the `dock_did_restart` reload, `place_editors` signals, and space-move/switch binds. In the no-SA branch: skip all of that. Keep in-space tiling (bsp, gaps, `manage=off` rules, focus/warp/resize, layout toggles, `space --balance/--mirror`) in BOTH branches. `skhdrc` can stay static — the `ctrl - N` / `ctrl+shift` space binds just fail harmlessly without SA; on the SIP-on volume lean on macOS-native spaces (`ctrl+←→`, enable `ctrl+number` in System Settings → Keyboard → Mission Control).

IMPORTANT: don't build blind — verify BOTH branches live (full mode on `Macintosh HD`, no-SA mode on the Beta volume) before shipping, per Karl's test-first rule.

UPDATE 2026-06-14: yabai **v7.1.25** (#2788, shipped 2026-05-08; Karl has it installed) makes `window --space <sel>` work **with SIP enabled / no SA** — routed through `SLSBridgedMoveWindowsToManagedSpaceOperation`, runtime-guarded by `if (SLSPerformAsynchronousBridgedWindowManagementOperation)`, plus `SLSSpaceSetFrontPSN` to front the moved app. Docs dropped the "SIP must be partially disabled" caveat for `--space`. SCOPE IS NARROW: only *moving* windows to spaces is fixed; **`space --focus` (switching the active space) still needs the SA**. Validated upstream on Tahoe 26.4 — NOT yet verified on macOS 27 Golden Gate (the bridged symbol may be absent on 27; the runtime guard degrades silently if so, so it's safe to wire in but must be tested live on the Beta volume per the test-first rule).

Implication for the no-SA branch (`mac/yabai/yabairc` ~L200-215, currently all gated behind HAS_SA=1): the skhdrc "send window to space N" binds can move into no-SA mode (real gain). `place_editors` can only PARTIALLY — it moves editors fine, but its float/reinsert layout build depends on `space --focus "$target"` (yabairc:90) which still needs SA, so it'd need a move-only reduced variant. Startup `space --focus 3` and `ctrl-N` space-switch binds stay SA-only; keep native macOS spaces in no-SA mode. NOT yet implemented — pending live verification on Golden Gate.

The SA boundary and the main no-restart design are documented in [[project-yabai-wake-no-restart]].
