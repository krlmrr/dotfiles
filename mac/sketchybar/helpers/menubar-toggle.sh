#!/bin/bash

# Toggle between sketchybar and native menu bar based on mouse position
TRIGGER_ZONE=10
LEAVE_ZONE=50
STATE="sketchy"

while true; do
  eval $(python3 -c "
import Quartz
loc = Quartz.NSEvent.mouseLocation()
h = Quartz.NSScreen.mainScreen().frame().size.height
print(f'MOUSE_Y={int(h - loc.y)}')
")

  if [ "$STATE" = "sketchy" ] && [ "$MOUSE_Y" -le "$TRIGGER_ZONE" ] 2>/dev/null; then
    yabai -m config menubar_opacity 1.0
    sketchybar --bar hidden=on
    STATE="native"
  elif [ "$STATE" = "native" ] && [ "$MOUSE_Y" -gt "$LEAVE_ZONE" ] 2>/dev/null; then
    yabai -m config menubar_opacity 0.0
    sketchybar --bar hidden=off
    STATE="sketchy"
  fi

  sleep 0.1
done
