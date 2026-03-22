#!/bin/sh

CURRENT_SPACE=$(yabai -m query --spaces --space 2>/dev/null | jq -r '.index')

ARGS=()
for sid in 1 2 3 4 5 6 7 8 9 10; do
  if [ "$sid" = "$CURRENT_SPACE" ]; then
    ARGS+=(--set space."$sid" background.drawing=on)
  else
    ARGS+=(--set space."$sid" background.drawing=off)
  fi
done

if [ "$SENDER" = "space_windows_change" ] || [ "$SENDER" = "space_change" ] || [ "$SENDER" = "forced" ]; then
  source "$CONFIG_DIR/plugins/icon_map.sh"
  WINDOWS=$(yabai -m query --windows 2>/dev/null)

  for sid in 1 2 3 4 5 6 7 8 9 10; do
    ICONS=""
    while IFS= read -r app; do
      [ -z "$app" ] && continue
      __icon_map "$app"
      ICONS="${ICONS}${icon_result} "
    done <<< "$(echo "$WINDOWS" | jq -r --argjson s "$sid" '[.[] | select(.space == $s and ."is-minimized" == false and ."is-hidden" == false and .role == "AXWindow")] | [.[].app] | unique | .[]' 2>/dev/null)"

    if [ -z "$ICONS" ]; then
      ARGS+=(--set space."$sid" label.drawing=off)
    else
      ARGS+=(--set space."$sid" label="${ICONS% }" label.font="sketchybar-app-font:Regular:13.0" label.drawing=on label.y_offset=-1)
    fi
  done
fi

sketchybar "${ARGS[@]}"
