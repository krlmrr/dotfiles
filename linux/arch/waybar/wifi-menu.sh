#!/bin/bash

# Get list of available wifi networks
networks=$(nmcli -t -f SSID,SIGNAL,SECURITY device wifi list | grep -v '^--' | sort -t: -k2 -nr | awk -F: '{
    if ($1 != "") {
        signal = $2
        security = ($3 != "") ? " 󰒃" : ""
        printf "%s %s%% %s\n", $1, signal, security
    }
}' | uniq)

if [ -z "$networks" ]; then
    notify-send "WiFi" "No networks found"
    exit 1
fi

# Show rofi menu
chosen=$(echo -e "󰤨 Rescan\n$networks" | rofi -dmenu -p "WiFi" -i)

if [ -z "$chosen" ]; then
    exit 0
fi

# Handle rescan
if [ "$chosen" = "󰤨 Rescan" ]; then
    nmcli device wifi rescan
    notify-send "WiFi" "Rescanning networks..."
    sleep 2
    exec "$0"
fi

# Extract SSID (first field before the percentage)
ssid=$(echo "$chosen" | sed 's/ [0-9]*%.*$//')

# Check if already connected
current=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
if [ "$current" = "$ssid" ]; then
    notify-send "WiFi" "Already connected to $ssid"
    exit 0
fi

# Check if we have a saved connection
if nmcli -t -f NAME connection show | grep -q "^$ssid$"; then
    nmcli connection up "$ssid" && notify-send "WiFi" "Connected to $ssid" || notify-send "WiFi" "Failed to connect"
else
    # Need password
    password=$(rofi -dmenu -p "Password for $ssid" -password)
    if [ -n "$password" ]; then
        nmcli device wifi connect "$ssid" password "$password" && notify-send "WiFi" "Connected to $ssid" || notify-send "WiFi" "Failed to connect"
    fi
fi
