#!/bin/bash
# Smart move to workspace - uses 1-5 on external, 6-10 on laptop
# Usage: movetoworkspace.sh <1-5>

WS=$1
# Single hyprctl call, extract both values with one jq
read -r CURRENT_MONITOR HAS_EXTERNAL <<< $(hyprctl monitors -j | jq -r '([.[] | select(.focused) | .name][0]) + " " + (if any(.[]; .name == "DP-1") then "1" else "0" end)')

if [ "$HAS_EXTERNAL" = "1" ] && [ "$CURRENT_MONITOR" = "eDP-1" ]; then
    hyprctl dispatch movetoworkspace $((WS + 5))
else
    hyprctl dispatch movetoworkspace $WS
fi
