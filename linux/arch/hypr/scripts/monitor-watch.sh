#!/bin/bash
# Poll for monitor changes and run workspace-setup.sh when detected

SCRIPT_DIR="$(dirname "$0")"
LAST_STATE=""

while true; do
    # Simpler check - just count monitors and check for DP-1
    CURRENT_STATE=$(hyprctl monitors -j | jq -r 'length, (any(.[]; .name == "DP-1"))')

    if [ "$CURRENT_STATE" != "$LAST_STATE" ] && [ -n "$LAST_STATE" ]; then
        sleep 1
        hyprctl reload
        sleep 1
        "$SCRIPT_DIR/workspace-setup.sh"
    fi

    LAST_STATE="$CURRENT_STATE"
    sleep 2
done
