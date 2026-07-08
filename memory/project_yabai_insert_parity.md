---
name: project-yabai-insert-parity
description: yabai --insert armed points survive successful warps (parity coin flip) — never prime insertion points; verify+repair geometry instead
metadata:
  type: project
---

Live-verified 2026-07-08 on yabai v7.1.25, SIP-on (macOS 27): a window's armed insertion point (`yabai -m window <id> --insert <dir>`) is **NOT consumed by a successful `--warp`** — it survives, and since re-issuing the same direction toggles it OFF and the armed state is unqueryable (not in `query --windows` JSON), any arm-then-warp scheme flips parity on every use: alternate calls go from honored-direction to nearest-area heuristic. Proven by running the identical arm+warp twice with opposite placements. DeepWiki/source-reading claimed consumed-on-success — wrong in practice; trust the live test.

**How to apply:** never prime insertion points in scripts. `warp_to` in `mac/yabai/yabairc` warps bare, then verifies pair geometry and repairs with `--toggle split` (wrong axis) + `--swap` (wrong order) — all tree-only and SIP-on safe. Also: `--warp` occasionally fails transiently at the OS level (logged as `[warp]` in /tmp/yabai.log); place re-invocation self-heals.

Related: [[project-yabai-sip-on-test]] (what works SIP-on), [[project-yabai-wake-no-restart]].
