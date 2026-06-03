#!/usr/bin/env sh
# After wake or display reconfiguration, yabai's BSP tree desyncs from the
# WindowServer: windows show is-floating=false but split=null, so they aren't
# in any tree and won't be managed until manually moved. Restarting the
# service rebuilds the tree.
#
# Space 2 chat windows are kept floating via manage=off per-app rules plus a
# trailing `yabai -m rule --apply` in yabairc — those primitives handle the
# float invariant correctly across restarts. No position save/restore is
# needed (we had one for a while, but it was working around a broken use of
# --toggle float on a float-layout space; removed once the rules-based fix
# proved sufficient).

yabai --restart-service
