#!/bin/bash

# Session manager - pure bash, no dependencies
# - Enter: switch to session
# - n: new session
# - r: rename session
# - d: detach session
# - x: kill session
# - X: kill all (except current)
# - j/k: navigate
# - Esc/q: cancel

current_session=$(tmux display-message -p '#S')

# Hide cursor, restore on exit
tput civis
trap 'tput cnorm' EXIT

# Build session list
build_sessions() {
    local filter="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
    sessions=()
    while IFS='|' read -r name windows attached; do
        # Skip if filter set and doesn't match (case-insensitive)
        local name_lower="$(echo "$name" | tr '[:upper:]' '[:lower:]')"
        if [ -n "$filter" ] && [[ "$name_lower" != *"$filter"* ]]; then
            continue
        fi
        if [ "$name" = "$current_session" ]; then
            marker="*"
        else
            marker=" "
        fi
        if [ -n "$attached" ]; then
            sessions+=("$marker $name|$windows windows  [attached]")
        else
            sessions+=("$marker $name|$windows windows")
        fi
    done < <(tmux list-sessions -F '#{session_name}|#{session_windows}|#{?session_attached,attached,}' 2>/dev/null)
}

build_sessions ""
[ ${#sessions[@]} -eq 0 ] && exit 0

selected=0
search_filter=""

# Get selected session name
get_selected_name() {
    local line="${sessions[$selected]}"
    echo "$line" | sed 's/^[* ] //' | cut -d'|' -f1 | xargs
}

# Main loop
while true; do
    # Clear and draw
    printf '\033[2J\033[H'

    rows=$(tput lines)
    cols=$(tput cols)

    # Draw sessions
    for i in "${!sessions[@]}"; do
        IFS='|' read -r left right <<< "${sessions[$i]}"

        printf '\033[%d;3H' $((i + 2))

        line="$left  $right"
        if [ $i -eq $selected ]; then
            printf '\033[48;2;62;68;82m%-*s\033[0m' "$((cols - 6))" "$line"
        else
            printf '%s' "$line"
        fi
    done

    # Draw filter status if active
    if [ -n "$search_filter" ]; then
        printf '\033[%d;3H' $((rows - 2))
        printf 'Filter: %s  (esc to clear)' "$search_filter"
    fi

    # Draw help
    printf '\033[%d;3H' $((rows - 1))
    printf '\033[38;2;92;99;112menter:switch  /:search  n:new  r:rename  d:detach  x:kill  X:all  q:quit\033[0m'

    # Read key
    read -rsn1 key

    case "$key" in
        j) ((selected < ${#sessions[@]} - 1)) && ((selected++)) ;;
        k) ((selected > 0)) && ((selected--)) ;;
        /)
            # Real-time search
            search_filter=""
            tput cnorm
            while true; do
                build_sessions "$search_filter"
                selected=0

                # Redraw with search prompt
                printf '\033[2J\033[H'
                for i in "${!sessions[@]}"; do
                    IFS='|' read -r left right <<< "${sessions[$i]}"
                    printf '\033[%d;3H' $((i + 2))
                    line="$left  $right"
                    if [ $i -eq $selected ]; then
                        printf '\033[48;2;62;68;82m%-*s\033[0m' "$((cols - 6))" "$line"
                    else
                        printf '%s' "$line"
                    fi
                done
                printf '\033[%d;3H' $((rows - 1))
                printf 'Search: %s' "$search_filter"

                read -rsn1 skey
                if [[ "$skey" == $'\e' ]]; then
                    search_filter=""
                    build_sessions ""
                    break
                elif [[ "$skey" == "" ]]; then
                    # Enter - keep filter and exit search mode
                    break
                elif [[ "$skey" == $'\x7f' || "$skey" == $'\b' ]]; then
                    search_filter="${search_filter%?}"
                else
                    search_filter+="$skey"
                fi
            done
            tput civis
            selected=0
            ;;
        n)
            printf '\033[%d;3H\033[K' $((rows - 1))
            printf 'New session name: '
            read -r new_name
            [ -n "$new_name" ] && tmux new-session -d -s "$new_name" && tmux switch-client -t "$new_name"
            exit 0
            ;;
        r)
            name=$(get_selected_name)
            printf '\033[%d;3H\033[K' $((rows - 1))
            printf 'Rename to: '
            read -r new_name
            [ -n "$new_name" ] && tmux rename-session -t "$name" "$new_name"
            ;;
        d)
            name=$(get_selected_name)
            tmux detach-client -s "$name" 2>/dev/null
            ;;
        x)
            name=$(get_selected_name)
            [ "$name" != "$current_session" ] && tmux kill-session -t "$name" 2>/dev/null
            build_sessions "$search_filter"
            [ ${#sessions[@]} -eq 0 ] && exit 0
            ((selected >= ${#sessions[@]})) && ((selected--))
            ;;
        X)
            tmux list-sessions -F '#S' | while read -r s; do
                [ "$s" != "$current_session" ] && tmux kill-session -t "$s" 2>/dev/null
            done
            build_sessions "$search_filter"
            selected=0
            ;;
        $'\e')
            # Esc clears filter, or exits if no filter
            if [ -n "$search_filter" ]; then
                search_filter=""
                build_sessions ""
                selected=0
            else
                exit 0
            fi
            ;;
        q)
            exit 0
            ;;
        "")
            name=$(get_selected_name)
            tmux switch-client -t "$name"
            exit 0
            ;;
    esac
done
