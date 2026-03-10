#!/bin/bash
# List running tray-style apps for waybar tooltip and menu

MODE=${1:-status}

# Define apps to track (name:process:class)
declare -A APPS=(
    ["Slack"]="slack:Slack"
    ["1Password"]="1password:1password"
    ["Discord"]="discord:discord"
    ["Spotify"]="spotify:Spotify"
)

get_running() {
    local running=""
    for name in "${!APPS[@]}"; do
        IFS=':' read -r proc class <<< "${APPS[$name]}"
        if pgrep -x "$proc" > /dev/null 2>&1; then
            running="${running}${name}\n"
        fi
    done
    echo -e "${running%\\n}"
}

case "$MODE" in
    status)
        apps=$(get_running)
        if [ -z "$apps" ]; then
            echo '{"text": "󰀻", "tooltip": "No background apps", "class": "empty"}'
        else
            tooltip=$(echo "$apps" | tr '\n' '\\' | sed 's/\\$//' | sed 's/\\/\\n/g')
            printf '{"text": "󰀻", "tooltip": "%s", "class": "active"}\n' "$tooltip"
        fi
        ;;
    menu)
        apps=$(get_running)
        if [ -z "$apps" ]; then
            notify-send "Apps" "No background apps running"
            exit 0
        fi

        chosen=$(echo -e "$apps" | rofi -dmenu -p "Apps" -i)
        [ -z "$chosen" ] && exit 0

        # Get the window class for the chosen app
        IFS=':' read -r proc class <<< "${APPS[$chosen]}"

        # Get window address and workspace, then focus
        window_info=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$class\") | \"\(.address) \(.workspace.id)\"" | head -1)
        read -r addr ws <<< "$window_info"

        if [ -n "$addr" ]; then
            hyprctl dispatch workspace "$ws"
            hyprctl dispatch focuswindow "address:$addr"
        fi
        ;;
esac
