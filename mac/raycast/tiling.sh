#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Tiling
# @raycast.mode silent
# @raycast.packageName yabai
# @raycast.icon 🪟
# @raycast.description Toggle yabai + sketchybar together

YABAI=/opt/homebrew/bin/yabai
BREW=/opt/homebrew/bin/brew

if pgrep -x yabai >/dev/null; then
  "$YABAI" --stop-service
  "$BREW" services stop sketchybar >/dev/null
  echo "Tiling OFF (yabai + sketchybar stopped)"
else
  "$YABAI" --start-service
  "$BREW" services start sketchybar >/dev/null
  echo "Tiling ON (yabai + sketchybar started)"
fi
