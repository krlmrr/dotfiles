echo "=== Mac Setup ==="

# Mac casks
echo "Installing Mac casks..."
brew install --cask \
    appcleaner \
    arc \
    balenaetcher \
    bambu-studio \
    blender \
    discord \
    fantastical \
    figma \
    ghostty \
    hammerspoon \
    herd \
    logi-options+ \
    orbstack \
    raycast \
    slack \
    tableplus \
    telegram \
    visual-studio-code \
    zed \
    zen

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
