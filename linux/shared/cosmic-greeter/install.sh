#!/bin/bash
# Install the cosmic-greeter wallpaper-sync helper, sudoers rule, and user
# systemd units. Idempotent — safe to re-run. Sourced from linux/fedora/setup.sh
# and runnable standalone (./linux/shared/cosmic-greeter/install.sh).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

id cosmic-greeter &>/dev/null || { echo "cosmic-greeter user not present — skipping"; exit 0; }

sudo install -m 755 "$DIR/sync-wallpaper.sh" /usr/local/sbin/cosmic-greeter-wallpaper-sync
sudo tee /etc/sudoers.d/cosmic-greeter-wallpaper-sync >/dev/null <<EOF
$USER ALL=(root) NOPASSWD: /usr/local/sbin/cosmic-greeter-wallpaper-sync
EOF
sudo chmod 440 /etc/sudoers.d/cosmic-greeter-wallpaper-sync
sudo visudo -cf /etc/sudoers.d/cosmic-greeter-wallpaper-sync >/dev/null

mkdir -p ~/.config/systemd/user
ln -snf "$DIR/cosmic-greeter-wallpaper-sync.service" ~/.config/systemd/user/cosmic-greeter-wallpaper-sync.service
ln -snf "$DIR/cosmic-greeter-wallpaper-sync.path"    ~/.config/systemd/user/cosmic-greeter-wallpaper-sync.path

systemctl --user daemon-reload
systemctl --user enable --now cosmic-greeter-wallpaper-sync.path

sudo -n /usr/local/sbin/cosmic-greeter-wallpaper-sync || true
echo "cosmic-greeter wallpaper sync installed"
