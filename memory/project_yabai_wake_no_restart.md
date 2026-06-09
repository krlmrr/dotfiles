---
name: project-yabai-wake-no-restart
description: yabai wake/display handling — never restart-service on wake; sleep breaks nothing
metadata:
  type: project
---

The yabai wake handler used to run `yabai --restart-service` on `system_woke`. That restart was the SOLE cause of every post-wake symptom: Zen/Zed/Ghostty flipping sides, Slack/Teams/Telegram demoting to `sub-layer below`, and chat windows reshuffling. Proven on 2026-06-08 with a log-only wake handler — two sleep/wake cycles with no restart left everything identical to the pre-sleep baseline.

The restart's original justification was bogus: a comment claimed `split=null` meant windows had fallen out of the BSP tree. `split` is just a leaf's pending-split direction; `null`/`none` is normal for almost every tiled window. So the restart fixed a non-problem and caused real ones.

Current design (no restart anywhere on wake): there is NO `system_woke` signal. Do NOT re-add a wake restart.

Everything is consolidated into ONE file — `mac/yabai/yabairc` — and ONE log, `/tmp/yabai.log`. `retile.sh`, `display-changed.sh`, and `display-layout.sh` were all deleted; their logic is now functions in `yabairc`, which re-invokes itself via signal actions: `yabairc display-change` (gated on the display signature actually changing) and `yabairc place` (on Zen/Zed/Ghostty `window_created`).

Editor placement (`place_editors`) is now DETERMINISTIC and idempotent: it skips when the layout is already correct, else rebuilds via float-then-reinsert with `--insert` (Zed = base/full-right; Zen re-tiles west; Ghostty re-tiles south of Zen) — no more `--warp` nondeterminism. The phantom roleless lowercase `ghostty` window is kept out of the tree by a `manage=off` rule (`^ghostty$`).

Still open: confirm yabai's display signals actually FIRE on a real dock/undock — one dock left the gate unrun (empty log). `/tmp/yabai.log` now records every invocation, so the next dock/undock will show whether the signal fires. See [[feedback-yabai-space2]], [[feedback-yabai-display-events]], [[feedback-no-sleep]].
