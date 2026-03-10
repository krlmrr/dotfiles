#!/bin/bash

# Get the active window class
active_class=$(hyprctl activewindow -j | jq -r '.class')

if [[ "$active_class" == *"zen"* ]] || [[ "$active_class" == *"Zen"* ]]; then
    # Zen Browser: send Ctrl+S for Compact Mode
    hyprctl dispatch sendshortcut "CTRL, S, activewindow"
else
    # Other apps: send Ctrl+B
    hyprctl dispatch sendshortcut "CTRL, B, activewindow"
fi
