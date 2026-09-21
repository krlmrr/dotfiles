#!/bin/sh

if [ "$SENDER" = "front_app_switched" ]; then
  source "$CONFIG_DIR/plugins/icon_map.sh"
  __icon_map "$INFO"
  sketchybar --set "$NAME" label.drawing=off icon="$icon_result"
fi
