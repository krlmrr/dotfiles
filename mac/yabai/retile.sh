#!/usr/bin/env sh
# After wake or display reconfiguration, yabai's BSP tree desyncs from the
# WindowServer: windows show is-floating=false but split=null, so they aren't
# in any tree and won't be managed until manually moved. Toggling float does
# not re-insert them, so we restart the service to rebuild the tree.

yabai --restart-service
