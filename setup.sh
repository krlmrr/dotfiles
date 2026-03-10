#!/bin/bash
set -e

# Keep sudo alive throughout the script
sudo -v

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DOTFILES_DIR/shared/functions.sh"

echo "Setting up dotfiles from $DOTFILES_DIR"

# Install core system packages (Linux)
if [ "$OS" = "linux" ]; then
    echo "Installing system packages..."
    sudo $PKG_UPDATE
    sudo $PKG git curl wget unzip zsh build-essential wl-clipboard
fi

# Git user info (only prompt if not already set)
GIT_NAME="$(git config --global user.name 2>/dev/null || true)"
GIT_EMAIL="$(git config --global user.email 2>/dev/null || true)"
if [ -z "$GIT_NAME" ]; then
    read -p "Git name: " GIT_NAME
fi
if [ -z "$GIT_EMAIL" ]; then
    read -p "Git email: " GIT_EMAIL
fi

# Homebrew
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ "$OS" = "linux" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
fi

# Shared formulae
echo "Installing shared brew formulae..."
brew install \
    gh \
    neovim \
    lazygit \
    ripgrep \
    fd

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-autosuggestions/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
fi

# Build .zshrc
bash "$DOTFILES_DIR/buildzshrc.sh"

# OS-specific setup
if [ "$OS" = "mac" ]; then
    echo "Running Mac setup..."
    source "$DOTFILES_DIR/mac/setup.sh"
else
    echo "Running Linux setup..."
    source "$DOTFILES_DIR/linux/setup.sh"
fi

# Claude Code
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
fi

# Symlink shared configs
echo "Linking shared configs..."
mkdir -p ~/.config

link "$DOTFILES_DIR/shared/nvim" ~/.config/nvim
link "$DOTFILES_DIR/shared/ghostty" ~/.config/ghostty
link "$DOTFILES_DIR/shared/lazygit" ~/.config/lazygit
link "$DOTFILES_DIR/shared/zed" ~/.config/zed

# Git
cp "$DOTFILES_DIR/shared/git/gitconfig" ~/.gitconfig
link "$DOTFILES_DIR/shared/git/gitignore_global" ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# Fonts
echo "Installing fonts..."
if [ "$OS" = "mac" ]; then
    cp -r "$DOTFILES_DIR/shared/fonts/"* ~/Library/Fonts/
else
    mkdir -p ~/.local/share/fonts
    cp -r "$DOTFILES_DIR/shared/fonts/"* ~/.local/share/fonts/
    fc-cache -fv
fi

echo "Done!"
