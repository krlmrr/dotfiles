#!/bin/bash
set -e

echo "=== Rolling back dotfiles ==="

# Remove symlinked configs
echo "Removing symlinked configs..."
rm -f ~/.config/nvim
rm -f ~/.config/ghostty
rm -f ~/.config/lazygit
rm -f ~/.config/zed
rm -f ~/.gitignore_global

# Remove mac-specific symlinks
rm -f ~/.hammerspoon
rm -f "$HOME/Library/Application Support/Code/User/settings.json" 2>/dev/null
rm -f "$HOME/Library/Application Support/Code/User/keybindings.json" 2>/dev/null
rm -f ~/.config/zed/keymap.json
rm -f ~/.vimrc
rm -f ~/.ideavimrc

# Remove arch-specific symlinks
rm -f ~/.config/hypr/hyprland.conf
rm -f ~/.config/hypr/hyprlock.conf
rm -f ~/.config/hypr/hypridle.conf
rm -f ~/.config/hypr/scripts
rm -f ~/.config/waybar
rm -f ~/.config/rofi
rm -f ~/.config/mako

# Restore default .zshrc
echo "Resetting .zshrc..."
if [ -f ~/.zshrc ]; then
    rm ~/.zshrc
    echo "Removed .zshrc (oh-my-zsh will regenerate on next login)"
fi

# Reset .gitconfig
echo "Resetting .gitconfig..."
rm -f ~/.gitconfig

echo "=== Rollback complete ==="
echo "Note: Installed packages (brew, apt, etc.) were left in place."
echo "Run 'source ~/.zshrc' or restart your terminal."
