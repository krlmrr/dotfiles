#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DOTFILES_DIR/shared/functions.sh"

echo "Configuring dotfiles from $DOTFILES_DIR"

# Git config
GIT_NAME="$(git config --global user.name 2>/dev/null || true)"
GIT_EMAIL="$(git config --global user.email 2>/dev/null || true)"
rm -f ~/.gitconfig
cp "$DOTFILES_DIR/shared/git/gitconfig" ~/.gitconfig
link "$DOTFILES_DIR/shared/git/gitignore_global" ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
[ -n "$GIT_NAME" ] && git config --global user.name "$GIT_NAME"
[ -n "$GIT_EMAIL" ] && git config --global user.email "$GIT_EMAIL"

# Build .zshrc
bash "$DOTFILES_DIR/buildzshrc.sh"

# Shared configs
mkdir -p ~/.config
link "$DOTFILES_DIR/shared/nvim" ~/.config/nvim
link "$DOTFILES_DIR/shared/lazygit" ~/.config/lazygit
if [ -d "$HOME/.var/app/dev.zed.Zed" ]; then
    link "$DOTFILES_DIR/shared/zed/settings.json" ~/.var/app/dev.zed.Zed/config/zed/settings.json
    link "$DOTFILES_DIR/shared/zed/themes" ~/.var/app/dev.zed.Zed/config/zed/themes
    link "$DOTFILES_DIR/linux/shared/zed-keymap.json" ~/.var/app/dev.zed.Zed/config/zed/keymap.json
else
    link "$DOTFILES_DIR/shared/zed" ~/.config/zed
fi

# Build Ghostty config
bash "$DOTFILES_DIR/buildghostty.sh"

# OS-specific configs
if [ "$OS" = "mac" ]; then
    link "$DOTFILES_DIR/mac/hammerspoon" ~/.hammerspoon
    open -a Hammerspoon
    mkdir -p "$HOME/Library/Application Support/Code/User"
    link "$DOTFILES_DIR/mac/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
    link "$DOTFILES_DIR/mac/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
    link "$DOTFILES_DIR/mac/zed-keymap.json" ~/.config/zed/keymap.json
    link "$DOTFILES_DIR/mac/phpstorm/vimrc" ~/.vimrc
    link "$DOTFILES_DIR/mac/phpstorm/ideavimrc" ~/.ideavimrc
fi

# Zen Browser user.js
zen_root() {
    if [ -d "$HOME/.var/app/app.zen_browser.zen/.zen" ]; then
        echo "$HOME/.var/app/app.zen_browser.zen/.zen"
    elif [ -d "$HOME/.zen" ]; then
        echo "$HOME/.zen"
    elif [ -d "$HOME/.config/zen" ]; then
        echo "$HOME/.config/zen"
    fi
}
ZEN_ROOT="$(zen_root)"
if [ -n "$ZEN_ROOT" ]; then
    find "$ZEN_ROOT" -maxdepth 1 -type d -name "*.*" | while read -r profile_dir; do
        cp "$DOTFILES_DIR/shared/zen/user.js" "$profile_dir/user.js"
    done
fi

echo "Done!"
