#!/bin/sh

source "$CONFIG_DIR/plugins/icon_map.sh"

SPACE_ID=$(echo "$NAME" | sed 's/space\.//')

ICONS=""
for app in $(yabai -m query --windows --space "$SPACE_ID" 2>/dev/null | jq -r '[.[] | select(."is-minimized" == false and ."is-hidden" == false)] | [.[].app] | unique | .[]'); do
  __icon_map "$app"
  ICONS="${ICONS}${icon_result} "
done

CURRENT_SPACE=$(yabai -m query --spaces --space 2>/dev/null | jq -r '.index')
if [ "$SPACE_ID" = "$CURRENT_SPACE" ]; then
  IS_SELECTED="on"
else
  IS_SELECTED="off"
fi

if [ -z "$ICONS" ]; then
  sketchybar --set "$NAME" icon="$SPACE_ID" icon.font="SF Pro:Regular:13.0" label.drawing=off background.drawing="$IS_SELECTED"
else
  sketchybar --set "$NAME" icon="$SPACE_ID" icon.font="SF Pro:Regular:13.0" label="${ICONS% }" label.font="sketchybar-app-font:Regular:13.0" label.drawing=on label.y_offset=-1 background.drawing="$IS_SELECTED"
fi
