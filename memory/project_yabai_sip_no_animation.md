---
name: project_yabai_sip_no_animation
description: yabai window animations are refused outright while SIP is enabled — no smoothing is available, so reduce the number of moves instead
metadata:
  type: project
---

**2026-09-01.** Every yabai move is a teleport on this machine and cannot be
smoothed. Setting the duration is refused by yabai itself:

```
$ yabai -m config window_animation_duration 0.30
command 'window_animation_duration' for domain 'config' requires System
Integrity Protection to be partially disabled! ignoring request..
```

Karl cannot turn SIP off. `window_animation_easing` is set and does nothing —
there is no duration to ease over. **Do not go looking for a smooth-animation
setting again; there isn't one.**

The only lever for "the layout jumps around" is therefore making **fewer and
smaller moves**. A rebuild is currently `warp` → re-measure → `--toggle split` /
`--swap` → `--balance`: up to three separate relayouts, each an unavoidable
visible jump. `warp_to` move-reduction is the open work item there.
