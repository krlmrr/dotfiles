#!/usr/bin/env sh
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Zsh
ln -sf $DOTFILES/zsh/zshrc $HOME/.zshrc

# Neovim
rm -rf $HOME/.config/nvim
ln -s $DOTFILES/nvim $HOME/.config/nvim

# Vimrc
rm -rf $HOME/.vimrc
ln -s $DOTFILES/vim/vimrc $HOME/.vimrc

# IdeaVim
rm -rf $HOME/.ideavimrc
ln -s $DOTFILES/vim/ideavimrc $HOME/.ideavimrc

# Git
ln -sf $DOTFILES/git/gitconfig $HOME/.gitconfig
ln -sf $DOTFILES/git/gitignore_global $HOME/.gitignore_global

# Tmux Plugin Manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Tmux
ln -sf $DOTFILES/tmux/tmux.conf $HOME/.tmux.conf

# Phpactor
rm -rf $HOME/.config/phpactor
ln -s $DOTFILES/phpactor $HOME/.config/phpactor

# Scripts
mkdir -p $HOME/.local/bin

# Homebrew
if ! command -v brew >/dev/null 2>&1
then
    echo "Brew is not installed"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
