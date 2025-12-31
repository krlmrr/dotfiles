#!/bin/bash

# Session manager with fzf
# - Enter: switch to session
# - n: new session
# - r: rename session
# - d: detach session
# - x: kill session
# - X: kill all (except current)
# - /: search
# - j/k: navigate
# - Esc: cancel

current_session=$(tmux display-message -p '#S')
# Get terminal width and subtract margins (3 each side + fzf pointer)
width=$(($(tput cols) - 9))

while true; do
    # Get sessions with details: name, windows, attached status (padded to full width)
    sessions=$(tmux list-sessions -F '#{session_name}|#{session_windows}|#{?session_attached,attached,}' 2>/dev/null | while IFS='|' read -r name windows attached; do
        if [ "$name" = "$current_session" ]; then
            marker="*"
        else
            marker=" "
        fi
        # Format: marker name (X windows) [attached] - padded to fill width
        if [ -n "$attached" ]; then
            printf "%-${width}s\n" "$(printf "%s %-20s %2s windows  [attached]" "$marker" "$name" "$windows")"
        else
            printf "%-${width}s\n" "$(printf "%s %-20s %2s windows" "$marker" "$name" "$windows")"
        fi
    done)

    # Exit if no sessions
    [ -z "$sessions" ] && exit 0

    # Run fzf with keybindings
    selected=$(echo "$sessions" | FZF_DEFAULT_OPTS="" fzf \
        --height=100% \
        --layout=reverse \
        --border=none \
        --margin=0,3 \
        --no-clear \
        --prompt="Search > " \
        --preview='echo "enter: switch | /: search | n: new | r: rename | d: detach | x: kill | X: kill all"' \
        --preview-window=bottom:1:wrap \
        --expect=n,r,d,x,X \
        --no-sort \
        --ansi \
        --disabled \
        --bind='/:enable-search,j:down,k:up,esc:abort' \
        --color='bg:-1,bg+:#3e4452,fg:#abb2bf,fg+:#abb2bf,hl:#61afef,hl+:#61afef,info:#e5c07b,prompt:#61afef,pointer:#98c379,marker:#98c379,header:#5c6370,gutter:-1,query:#abb2bf,spinner:-1,border:-1,preview-bg:-1')

    # Parse fzf output (first line is the key pressed, second is selection)
    key=$(echo "$selected" | head -1)
    # Extract session name (second field, trim whitespace)
    choice=$(echo "$selected" | tail -1 | awk '{print $2}')

    if [ "$key" = "n" ]; then
        # New session - use second fzf as input
        session_name=$(echo "" | fzf --height=100% --layout=reverse --border=none --margin=1,3 --print-query --prompt="New session > " --header="Enter name and press Enter" --color='bg:-1,bg+:#3e4452,fg:#abb2bf,fg+:#abb2bf,prompt:#61afef,header:#5c6370,gutter:-1' | head -1)
        if [ -n "$session_name" ]; then
            tmux new-session -d -s "$session_name"
            tmux switch-client -t "$session_name"
            exit 0
        fi
        # Loop back if cancelled
    elif [ "$key" = "r" ]; then
        # Rename session - use second fzf as input
        if [ -n "$choice" ]; then
            new_name=$(echo "" | fzf --height=100% --layout=reverse --border=none --margin=1,3 --print-query --query="$choice" --prompt="Rename to > " --header="Edit name and press Enter" --color='bg:-1,bg+:#3e4452,fg:#abb2bf,fg+:#abb2bf,prompt:#61afef,header:#5c6370,gutter:-1' | head -1)
            if [ -n "$new_name" ]; then
                tmux rename-session -t "$choice" "$new_name"
                [ "$choice" = "$current_session" ] && current_session="$new_name"
            fi
        fi
        # Loop back to show updated list
    elif [ "$key" = "d" ]; then
        # Detach all clients from selected session
        if [ -n "$choice" ]; then
            tmux detach-client -s "$choice" 2>/dev/null
        fi
        # Loop back to show updated list
    elif [ "$key" = "x" ]; then
        # Kill the selected session
        if [ -n "$choice" ] && [ "$choice" != "$current_session" ]; then
            tmux kill-session -t "$choice" 2>/dev/null
        fi
        # Loop back to show updated list
    elif [ "$key" = "X" ]; then
        # Kill all sessions except current
        tmux list-sessions -F '#S' | while read -r session; do
            [ "$session" != "$current_session" ] && tmux kill-session -t "$session" 2>/dev/null
        done
        # Loop back to show updated list
    elif [ -n "$choice" ]; then
        # Switch to selected session
        tmux switch-client -t "$choice"
        exit 0
    else
        # Nothing selected, exit
        exit 0
    fi
done
