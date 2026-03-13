echo "=== Mac Setup ==="

# Mac packages
echo "Installing Mac packages..."
brew bundle --file="$DOTFILES_DIR/mac/Brewfile"

# Caps Lock → Control (at boot via LaunchDaemon, Hammerspoon adds tap-for-Escape)
sudo cp "$DOTFILES_DIR/mac/CapsLockToControl.plist" /Library/LaunchDaemons/com.dotfiles.CapsLockToControl.plist
sudo chown root:wheel /Library/LaunchDaemons/com.dotfiles.CapsLockToControl.plist
sudo chmod 644 /Library/LaunchDaemons/com.dotfiles.CapsLockToControl.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.dotfiles.CapsLockToControl.plist 2>/dev/null || true

# Hammerspoon
link "$DOTFILES_DIR/mac/hammerspoon" ~/.hammerspoon

# VS Code
mkdir -p "$HOME/Library/Application Support/Code/User"
link "$DOTFILES_DIR/mac/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
link "$DOTFILES_DIR/mac/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"

# Sketchybar
link "$DOTFILES_DIR/mac/sketchybar" ~/.config/sketchybar

# yabai + skhd (tiling window manager)
link "$DOTFILES_DIR/mac/yabai/yabairc" ~/.yabairc
link "$DOTFILES_DIR/mac/yabai/skhdrc" ~/.skhdrc

# Zed keymap (mac-specific)
link "$DOTFILES_DIR/mac/zed-keymap.json" ~/.config/zed/keymap.json

# IdeaVim (PhpStorm)
link "$DOTFILES_DIR/mac/phpstorm/vimrc" ~/.vimrc
link "$DOTFILES_DIR/mac/phpstorm/ideavimrc" ~/.ideavimrc

echo "=== Mac setup complete ==="
