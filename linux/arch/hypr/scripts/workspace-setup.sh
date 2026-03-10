#!/bin/bash
# Dynamic workspace setup based on connected monitors
# - With external: 1-5 on external, 6-10 on laptop
# - Without external: 1-5 on laptop only

WAYBAR_BASE="$HOME/dotfiles/waybar/config.jsonc"
WAYBAR_LIVE="$HOME/.config/waybar/config.jsonc"

# Check if external monitor is connected (single hyprctl call)
if hyprctl monitors -j | jq -e 'any(.[]; .name == "DP-1")' > /dev/null 2>&1; then
    # Dual monitor setup

    # Batch workspace bindings for DP-1
    hyprctl --batch "keyword workspace 1,monitor:DP-1; keyword workspace 2,monitor:DP-1; keyword workspace 3,monitor:DP-1,default:true; keyword workspace 4,monitor:DP-1; keyword workspace 5,monitor:DP-1"

    # Batch workspace bindings for eDP-1
    hyprctl --batch "keyword workspace 6,monitor:eDP-1; keyword workspace 7,monitor:eDP-1; keyword workspace 8,monitor:eDP-1,default:true; keyword workspace 9,monitor:eDP-1; keyword workspace 10,monitor:eDP-1"

    # Move workspaces to monitors
    hyprctl --batch "dispatch moveworkspacetomonitor 1 DP-1; dispatch moveworkspacetomonitor 2 DP-1; dispatch moveworkspacetomonitor 3 DP-1; dispatch moveworkspacetomonitor 4 DP-1; dispatch moveworkspacetomonitor 5 DP-1" 2>/dev/null
    hyprctl --batch "dispatch moveworkspacetomonitor 6 eDP-1; dispatch moveworkspacetomonitor 7 eDP-1; dispatch moveworkspacetomonitor 8 eDP-1; dispatch moveworkspacetomonitor 9 eDP-1; dispatch moveworkspacetomonitor 10 eDP-1" 2>/dev/null

    # Ensure default workspaces exist and switch to primary
    hyprctl --batch "dispatch workspace 8; dispatch workspace 3"

    # Update waybar config - dual monitor persistent-workspaces
    jq '."hyprland/workspaces"."persistent-workspaces" = {"DP-1": [1,2,3,4,5], "eDP-1": [6,7,8,9,10]}' "$WAYBAR_BASE" > "${WAYBAR_LIVE}.tmp" && mv "${WAYBAR_LIVE}.tmp" "$WAYBAR_LIVE"

else
    # Single laptop monitor

    # Move windows from 6-10 to 1-5 (single hyprctl clients call)
    CLIENTS=$(hyprctl clients -j)
    for ws in 6 7 8 9 10; do
        target=$((ws - 5))
        echo "$CLIENTS" | jq -r ".[] | select(.workspace.id == $ws) | .address" | while read -r addr; do
            [ -n "$addr" ] && hyprctl dispatch movetoworkspace "$target,address:$addr"
        done
    done

    # Batch workspace bindings for eDP-1
    hyprctl --batch "keyword workspace 1,monitor:eDP-1; keyword workspace 2,monitor:eDP-1; keyword workspace 3,monitor:eDP-1,default:true; keyword workspace 4,monitor:eDP-1; keyword workspace 5,monitor:eDP-1"

    # Move workspaces to laptop
    hyprctl --batch "dispatch moveworkspacetomonitor 1 eDP-1; dispatch moveworkspacetomonitor 2 eDP-1; dispatch moveworkspacetomonitor 3 eDP-1; dispatch moveworkspacetomonitor 4 eDP-1; dispatch moveworkspacetomonitor 5 eDP-1" 2>/dev/null

    # Switch to workspace 3
    hyprctl dispatch workspace 3

    # Update waybar config - single monitor persistent-workspaces
    jq '."hyprland/workspaces"."persistent-workspaces" = {"eDP-1": [1,2,3,4,5]}' "$WAYBAR_BASE" > "${WAYBAR_LIVE}.tmp" && mv "${WAYBAR_LIVE}.tmp" "$WAYBAR_LIVE"
fi

# Restart waybar
pkill waybar
sleep 0.2
hyprctl dispatch exec waybar
