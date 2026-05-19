#!/bin/bash
set -e

echo "=== Linux Setup ==="

# Create project directories
mkdir -p ~/Sites ~/Code

# Linux-only brew formulae
echo "Installing Linux brew formulae..."
brew bundle --file="$DOTFILES_DIR/linux/Brewfile"

# Distro-specific setup (keyd, ghostty, etc.)
if [ "$DISTRO" = "deb" ]; then
    echo "Running Debian/Ubuntu setup..."
    source "$DOTFILES_DIR/linux/deb/setup.sh"
elif [ "$DISTRO" = "arch" ]; then
    echo "Running Arch setup..."
    source "$DOTFILES_DIR/linux/arch/setup.sh"
elif [ "$DISTRO" = "fedora" ]; then
    echo "Running Fedora setup..."
    source "$DOTFILES_DIR/linux/fedora/setup.sh"
fi

# Udev rule for Keychron keyboards (Via/WebHID)
echo "Setting up Keychron udev rule..."
sudo tee /etc/udev/rules.d/99-keychron-via.rules > /dev/null <<'EOF'
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", MODE="0666"
EOF
sudo udevadm control --reload-rules
sudo udevadm trigger

# Default browser — Zen is installed natively (COPR on Fedora, wakemeops on Deb).
if command -v zen-browser &>/dev/null; then
    echo "Setting Zen Browser as default..."
    xdg-settings set default-web-browser zen-browser.desktop
fi

# COSMIC desktop config
if [ "$XDG_CURRENT_DESKTOP" = "COSMIC" ]; then
    echo "Configuring COSMIC desktop..."
    mkdir -p ~/.config/cosmic
    for dir in "$DOTFILES_DIR/linux/shared/cosmic/"*/; do
        name=$(basename "$dir")
        cp -a --force "$dir"/. "$HOME/.config/cosmic/$name/"
    done
    # Restart components that don't auto-reload from new config files.
    # cosmic-bg: wallpaper changes. cosmic-panel: panel entries changes (otherwise
    # old panel instances stay running alongside the new ones, e.g. duplicate top bar).
    # cosmic-comp is intentionally NOT restarted — would crash the session.
    pkill cosmic-bg 2>/dev/null || true
    pkill cosmic-panel 2>/dev/null || true

    # cosmic-greeter wallpaper sync — must run after the COSMIC config copy above,
    # otherwise the install-time initial sync sees an empty source dir and no-ops.
    # Self-guards on the cosmic-greeter user existing.
    source "$DOTFILES_DIR/linux/shared/cosmic-greeter/install.sh"
fi

echo "=== Linux setup complete ==="
