#!/bin/bash
set -e

echo "=== Rolling back dotfiles ==="

# Remove symlinked configs
echo "Removing symlinked configs..."
rm -f ~/.config/nvim
rm -f ~/.config/ghostty/config
rm -f ~/.config/ghostty/themes
rm -f "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
rm -f "$HOME/Library/Application Support/com.mitchellh.ghostty/themes"
rm -f ~/.config/lazygit
rm -f ~/.config/zed/settings.json
rm -f ~/.config/zed/themes
rm -f ~/.config/zed/keymap.json
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

# Legacy: configure used to link these from the since-deleted mac/phpstorm/.
# Machines that ran the old script still have them as dangling symlinks.
rm -f ~/.vimrc
rm -f ~/.ideavimrc

# Restore default .zshrc
echo "Resetting .zshrc..."
# ~/.zshrc is a generated shim (a real file, not a symlink) that sources
# zsh/zshrc. Removing it also discards anything Herd or an installer appended.
if [ -f ~/.zshrc ] || [ -L ~/.zshrc ]; then
    rm -f ~/.zshrc
    echo "Removed .zshrc shim (oh-my-zsh will regenerate on next login)"
fi

# Reset .gitconfig and the generated identity include
echo "Resetting .gitconfig..."
rm -f ~/.gitconfig
rm -f ~/.config/git/identity

echo "=== Rollback complete ==="
echo "Note: Installed packages (brew) were left in place."
echo "Run 'source ~/.zshrc' or restart your terminal."
