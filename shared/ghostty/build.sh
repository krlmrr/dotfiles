#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$DOTFILES_DIR/shared/functions.sh"

echo "Building Ghostty config..."
rm -rf ~/.config/ghostty
mkdir -p ~/.config/ghostty
cp "$DOTFILES_DIR/shared/ghostty/config" ~/.config/ghostty/config
link "$DOTFILES_DIR/shared/ghostty/themes" ~/.config/ghostty/themes

if [ "$OS" = "mac" ]; then
    append "font-size = 18" ~/.config/ghostty/config
    append "window-padding-y = 8,8" ~/.config/ghostty/config
    append "window-padding-x = 8,8" ~/.config/ghostty/config

    # macOS also reads from Application Support
    mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
    cp ~/.config/ghostty/config "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
    link "$DOTFILES_DIR/shared/ghostty/themes" "$HOME/Library/Application Support/com.mitchellh.ghostty/themes"
elif [ "$OS" = "linux" ]; then
    append "window-decoration = false" ~/.config/ghostty/config
    append "font-size = 12" ~/.config/ghostty/config
    append "window-padding-y = 8,4" ~/.config/ghostty/config
    append "window-padding-x = 4,4" ~/.config/ghostty/config
fi

echo "Ghostty config rebuilt."
