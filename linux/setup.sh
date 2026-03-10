#!/bin/bash
set -e

echo "=== Linux Setup ==="

# Update package manager
echo "Updating packages..."
sudo $PKG_UPDATE

# Install core packages
echo "Installing system packages..."
sudo $PKG \
    git \
    curl \
    wget \
    unzip \
    zsh

# Linux-only brew formulae
echo "Installing Linux brew formulae..."
brew install lazydocker

# Distro-specific setup (docker, keyd, ddev, ghostty, etc.)
if [ "$DISTRO" = "deb" ]; then
    echo "Running Debian/Ubuntu setup..."
    source "$DOTFILES_DIR/linux/deb/setup.sh"
elif [ "$DISTRO" = "arch" ]; then
    echo "Running Arch setup..."
    source "$DOTFILES_DIR/linux/arch/setup.sh"
fi

# keyd config (caps lock -> ctrl/esc)
sudo mkdir -p /etc/keyd
sudo tee /etc/keyd/default.conf > /dev/null <<'EOF'
[ids]
*

[main]
capslock = overload(control, esc)
EOF
sudo systemctl enable --now keyd

# Udev rule for Keychron Q8 (Via)
echo "Setting up Keychron Q8 udev rule..."
sudo tee /etc/udev/rules.d/99-keychron-via.rules > /dev/null <<'EOF'
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0181", MODE="0666"
EOF
sudo udevadm control --reload-rules
sudo udevadm trigger

echo "=== Linux setup complete ==="
