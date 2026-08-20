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
rm -f ~/.config/jj/config.toml
rm -rf ~/.config/jj/conf.d

# Remove mac-specific symlinks
rm -f ~/.hammerspoon
rm -f ~/.config/sketchybar
rm -f ~/.yabairc
rm -f ~/.skhdrc
rm -f "$HOME/Library/Application Support/Code/User/settings.json" 2>/dev/null
rm -f "$HOME/Library/Application Support/Code/User/keybindings.json" 2>/dev/null
rm -f ~/.config/zed/keymap.json

# Legacy: configure used to link these from the since-deleted mac/phpstorm/.
# Machines that ran the old script still have them as dangling symlinks.
rm -f ~/.vimrc
rm -f ~/.ideavimrc

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
echo "Note: Installed packages (brew) were left in place."
echo "Run 'source ~/.zshrc' or restart your terminal."
