echo "=== Arch (CachyOS) Setup ==="

# Docker
if ! command -v docker &> /dev/null; then
    pacman_install docker
    sudo usermod -aG docker "$USER"
fi

# Arch-specific packages
pacman_install keyd hyprland hyprlock hypridle waybar rofi-wayland mako sddm

# keyd config (caps lock -> ctrl/esc)
sudo mkdir -p /etc/keyd
sudo ln -snf "$DOTFILES_DIR/linux/shared/keyd/default.conf" /etc/keyd/default.conf
sudo ln -snf "$DOTFILES_DIR/linux/shared/keyd/dell.conf" /etc/keyd/dell.conf
sudo systemctl enable --now keyd

# AUR packages
if command -v yay &> /dev/null; then
    if ! pacman -Q ddev-bin &>/dev/null; then
        yay -S --noconfirm ddev-bin
    fi
fi

# DDEV global config
ddev config global --project-tld=test
mkcert -install

# Hyprland
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
