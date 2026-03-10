#!/bin/bash

choice=$(echo -e "Logout\nRestart\nShutdown\nCancel" | rofi -dmenu -p "Power" -theme-str 'window {width: 600px;} element-text {horizontal-align: 0.5;}')

case "$choice" in
    Logout)
        hyprctl dispatch exit
        ;;
    Restart)
        systemctl reboot
        ;;
    Shutdown)
        systemctl poweroff
        ;;
    *)
        exit 0
        ;;
esac
