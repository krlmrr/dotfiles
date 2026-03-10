#!/bin/bash

# Check if bluetooth is powered on
power_status=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

if [ "$power_status" = "no" ]; then
    choice=$(echo -e "󰂯 Power On\n󰂲 Cancel" | rofi -dmenu -p "Bluetooth Off")
    if [ "$choice" = "󰂯 Power On" ]; then
        bluetoothctl power on
        notify-send "Bluetooth" "Powered on"
        sleep 1
        exec "$0"
    fi
    exit 0
fi

# Get paired devices
paired=$(bluetoothctl devices Paired | while read -r _ mac name; do
    connected=$(bluetoothctl info "$mac" 2>/dev/null | grep "Connected:" | awk '{print $2}')
    if [ "$connected" = "yes" ]; then
        echo "󰂱 $name (connected)"
    else
        echo "󰂯 $name"
    fi
done)

# Build menu
menu="󰂰 Scan for devices\n󰂲 Power Off"
if [ -n "$paired" ]; then
    menu="$paired\n$menu"
fi

chosen=$(echo -e "$menu" | rofi -dmenu -p "Bluetooth" -i)

if [ -z "$chosen" ]; then
    exit 0
fi

case "$chosen" in
    "󰂰 Scan for devices")
        notify-send "Bluetooth" "Scanning for devices..."
        bluetoothctl --timeout 5 scan on &
        sleep 5

        # Get available devices
        available=$(bluetoothctl devices | while read -r _ mac name; do
            echo "$name|$mac"
        done)

        device=$(echo "$available" | awk -F'|' '{print $1}' | rofi -dmenu -p "Select device" -i)

        if [ -n "$device" ]; then
            mac=$(echo "$available" | grep "^$device|" | awk -F'|' '{print $2}')
            if [ -n "$mac" ]; then
                notify-send "Bluetooth" "Connecting to $device..."
                bluetoothctl pair "$mac" 2>/dev/null
                bluetoothctl trust "$mac" 2>/dev/null
                bluetoothctl connect "$mac" && notify-send "Bluetooth" "Connected to $device" || notify-send "Bluetooth" "Failed to connect"
            fi
        fi
        ;;
    "󰂲 Power Off")
        bluetoothctl power off
        notify-send "Bluetooth" "Powered off"
        ;;
    *)
        # Handle device selection (connect/disconnect)
        device_name=$(echo "$chosen" | sed 's/^󰂱 //;s/^󰂯 //;s/ (connected)$//')
        mac=$(bluetoothctl devices Paired | grep "$device_name" | awk '{print $2}')

        if [ -n "$mac" ]; then
            connected=$(bluetoothctl info "$mac" 2>/dev/null | grep "Connected:" | awk '{print $2}')
            if [ "$connected" = "yes" ]; then
                bluetoothctl disconnect "$mac" && notify-send "Bluetooth" "Disconnected from $device_name"
            else
                notify-send "Bluetooth" "Connecting to $device_name..."
                bluetoothctl connect "$mac" && notify-send "Bluetooth" "Connected to $device_name" || notify-send "Bluetooth" "Failed to connect"
            fi
        fi
        ;;
esac
