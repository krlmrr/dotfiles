#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$DOTFILES_DIR/shared/functions.sh"

echo "Building .zshrc..."
cp "$DOTFILES_DIR/shared/zsh/zshrc" ~/.zshrc
echo "" >> ~/.zshrc
cat "$DOTFILES_DIR/shared/zsh/aliases.sh" >> ~/.zshrc

if [ "$OS" = "mac" ]; then
    echo "" >> ~/.zshrc
    cat "$DOTFILES_DIR/mac/zsh/aliases.sh" >> ~/.zshrc
else
    echo "" >> ~/.zshrc
    cat "$DOTFILES_DIR/linux/shared/zsh/aliases.sh" >> ~/.zshrc
fi

echo ".zshrc rebuilt. Run 'source ~/.zshrc' to reload."
