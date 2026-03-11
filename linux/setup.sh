#!/bin/bash
set -e

echo "=== Linux Setup ==="

# Create project directories
mkdir -p ~/Sites ~/Code

# Linux-only brew formulae
echo "Installing Linux brew formulae..."
brew_install lazydocker

# Distro-specific setup (docker, keyd, ddev, ghostty, etc.)
if [ "$DISTRO" = "deb" ]; then
    echo "Running Debian/Ubuntu setup..."
    source "$DOTFILES_DIR/linux/deb/setup.sh"
elif [ "$DISTRO" = "arch" ]; then
    echo "Running Arch setup..."
    source "$DOTFILES_DIR/linux/arch/setup.sh"
fi

# Udev rule for Keychron Q8 (Via)
echo "Setting up Keychron Q8 udev rule..."
sudo tee /etc/udev/rules.d/99-keychron-via.rules > /dev/null <<'EOF'
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0181", MODE="0666"
EOF
sudo udevadm control --reload-rules
sudo udevadm trigger

# Default browser
if command -v zen &>/dev/null; then
    echo "Setting Zen Browser as default..."
    xdg-settings set default-web-browser zen.desktop
fi

# COSMIC desktop config
if [ "$XDG_CURRENT_DESKTOP" = "COSMIC" ]; then
    echo "Configuring COSMIC desktop..."
    mkdir -p ~/.config/cosmic
    for dir in "$DOTFILES_DIR/linux/shared/cosmic/"*/; do
        name=$(basename "$dir")
        cp -a --force "$dir"/. "$HOME/.config/cosmic/$name/"
    done
    # Restart cosmic-bg to apply wallpaper
    pkill cosmic-bg 2>/dev/null || true
fi

echo "=== Linux setup complete ==="
