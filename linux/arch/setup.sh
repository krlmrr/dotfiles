echo "=== Arch (CachyOS) Setup ==="

# Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo pacman -S --noconfirm docker
    sudo usermod -aG docker "$USER"
fi

# keyd
if ! command -v keyd &> /dev/null; then
    echo "Installing keyd..."
    sudo pacman -S --noconfirm keyd
fi

# Arch-specific packages
echo "Installing Arch packages..."
sudo $PKG \
    hyprland \
    hyprlock \
    hypridle \
    waybar \
    rofi-wayland \
    mako \
    sddm

# AUR packages
if command -v yay &> /dev/null; then
    yay -S --noconfirm \
        ddev-bin
fi

# DDEV global config
ddev config global --project-tld=test

# Hyprland
mkdir -p ~/.config/hypr
link "$DOTFILES_DIR/linux/arch/hypr/hyprland.conf" ~/.config/hypr/hyprland.conf
link "$DOTFILES_DIR/linux/arch/hypr/hyprlock.conf" ~/.config/hypr/hyprlock.conf
link "$DOTFILES_DIR/linux/arch/hypr/hypridle.conf" ~/.config/hypr/hypridle.conf
link "$DOTFILES_DIR/linux/arch/hypr/scripts" ~/.config/hypr/scripts

# Waybar
link "$DOTFILES_DIR/linux/arch/waybar" ~/.config/waybar

# Rofi
link "$DOTFILES_DIR/linux/arch/rofi" ~/.config/rofi

# Mako
link "$DOTFILES_DIR/linux/arch/mako" ~/.config/mako

# SDDM
echo "Setting up SDDM..."
sudo cp "$DOTFILES_DIR/linux/arch/sddm/sddm.conf" /etc/sddm.conf
sudo mkdir -p /usr/share/sddm/themes
sudo cp "$DOTFILES_DIR/linux/arch/sddm/theme.conf" /usr/share/sddm/themes/
sudo cp "$DOTFILES_DIR/linux/arch/sddm/themes/onedark.conf" /usr/share/sddm/themes/
sudo cp "$DOTFILES_DIR/linux/arch/sddm/Xsetup" /usr/share/sddm/scripts/Xsetup
sudo systemctl enable sddm

echo "=== Arch setup complete ==="
