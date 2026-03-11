echo "=== Mac Setup ==="

# Mac formulae
brew_install mole

# Mac casks
echo "Installing Mac casks..."
brew_install_cask appcleaner arc balenaetcher bambu-studio blender discord \
    fantastical figma ghostty hammerspoon herd logi-options+ orbstack \
    raycast slack tableplus telegram visual-studio-code zed zen

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

# Zed keymap (mac-specific)
link "$DOTFILES_DIR/mac/zed-keymap.json" ~/.config/zed/keymap.json

# IdeaVim (PhpStorm)
link "$DOTFILES_DIR/mac/phpstorm/vimrc" ~/.vimrc
link "$DOTFILES_DIR/mac/phpstorm/ideavimrc" ~/.ideavimrc

echo "=== Mac setup complete ==="
