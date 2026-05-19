echo "=== Arch (CachyOS) Setup ==="

# Arch-specific packages
pacman_install keyd hyprland hyprlock hypridle waybar rofi-wayland mako sddm podman

# Lerd (podman-based Laravel local dev environment)
if ! command -v lerd &>/dev/null; then
    echo "Installing Lerd..."
    curl -fsSL https://raw.githubusercontent.com/geodro/lerd/main/install.sh | bash
fi

# keyd config (caps lock -> ctrl/esc)
sudo mkdir -p /etc/keyd
sudo ln -snf "$DOTFILES_DIR/linux/shared/keyd/default.conf" /etc/keyd/default.conf
sudo ln -snf "$DOTFILES_DIR/linux/shared/keyd/dell.conf" /etc/keyd/dell.conf
sudo systemctl enable --now keyd

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
