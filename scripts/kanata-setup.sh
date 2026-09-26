#!/usr/bin/env bash
set -euo pipefail

DRIVER_VERSION="6.2.0"
DRIVER_PKG="Karabiner-DriverKit-VirtualHIDDevice-${DRIVER_VERSION}.pkg"
DRIVER_URL="https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v${DRIVER_VERSION}/${DRIVER_PKG}"
DRIVER_MANAGER="/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"
VHID_DAEMON="/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
VHID_LABEL="org.pqrs.Karabiner-VirtualHIDDevice-Daemon"
KANATA_LABEL="dev.kanata.kanata"
KANATA_BIN="/opt/homebrew/opt/kanata/bin/kanata"
KANATA_CFG="$HOME/.config/kanata/kanata.kbd"

if [ "$(uname)" != "Darwin" ]; then
    echo "kanata-setup is macOS only."
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
    echo "Run this as yourself, not with sudo. It asks for sudo when it needs it."
    exit 1
fi

if [ ! -x "$KANATA_BIN" ]; then
    echo "kanata is not installed. Run: brew install kanata"
    exit 1
fi

if [ ! -f "$KANATA_CFG" ]; then
    echo "No config at $KANATA_CFG. Run dot install first so the kanata package is stowed."
    exit 1
fi

"$KANATA_BIN" --cfg "$KANATA_CFG" --check >/dev/null

brew pin kanata
echo "Pinned kanata: driver v${DRIVER_VERSION} only supports kanata < 1.13. Upgrade both together."

if [ ! -x "$DRIVER_MANAGER" ]; then
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    echo "Downloading Karabiner VirtualHIDDevice driver v${DRIVER_VERSION}..."
    curl -fsSL -o "$tmp/$DRIVER_PKG" "$DRIVER_URL"
    sudo installer -pkg "$tmp/$DRIVER_PKG" -target /
fi

sudo "$DRIVER_MANAGER" forceActivate

install_daemon() {
    label="$1"
    plist="/Library/LaunchDaemons/$label.plist"
    tmp_plist="$(mktemp)"
    cat > "$tmp_plist"
    sudo launchctl bootout "system/$label" 2>/dev/null || true
    sudo install -m 644 -o root -g wheel "$tmp_plist" "$plist"
    rm -f "$tmp_plist"
    sudo launchctl bootstrap system "$plist"
    echo "Loaded $label"
}

install_daemon "$VHID_LABEL" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$VHID_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$VHID_DAEMON</string>
    </array>
    <key>UserName</key>
    <string>root</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/karabiner-vhid-daemon.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/karabiner-vhid-daemon.log</string>
</dict>
</plist>
EOF

install_daemon "$KANATA_LABEL" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$KANATA_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$KANATA_BIN</string>
        <string>--cfg</string>
        <string>$KANATA_CFG</string>
    </array>
    <key>UserName</key>
    <string>root</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>StandardOutPath</key>
    <string>/var/log/kanata.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/kanata.log</string>
</dict>
</plist>
EOF

cat <<EOF

Almost done. Finish these in System Settings:

  1. General > Login Items & Extensions > Driver Extensions
     Turn on: org.pqrs.Karabiner-DriverKit-VirtualHIDDevice

  2. Privacy & Security > Input Monitoring
     Add: $(readlink -f "$KANATA_BIN")
     (Press Cmd+Shift+G in the file picker and paste the path.)

  3. Privacy & Security > Accessibility
     Add the same path.

  4. Restart kanata:
     sudo launchctl kickstart -k system/$KANATA_LABEL

Logs: /var/log/kanata.log
Reload after editing kanata.kbd: sudo launchctl kickstart -k system/$KANATA_LABEL
EOF
