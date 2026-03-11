#!/bin/bash
set -e

# Keep sudo alive throughout the script
sudo -v
while true; do sudo -v; sleep 30; done 2>/dev/null &
SUDO_PID=$!

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DOTFILES_DIR/shared/functions.sh"

echo "Setting up dotfiles from $DOTFILES_DIR"

# Install core system packages (Linux)
if [ "$OS" = "linux" ]; then
    echo "Updating system..."
    sudo $PKG_UPDATE
    if [ -n "$PKG_UPGRADE" ]; then
        sudo $PKG_UPGRADE
    fi
    echo "Installing system packages..."
    if [ "$DISTRO" = "arch" ]; then
        sudo pacman -S --needed --noconfirm base-devel
        pacman_install git curl wget unzip zsh wl-clipboard
    else
        apt_install git curl wget unzip zsh build-essential wl-clipboard
    fi
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

# Git config
rm -f ~/.gitconfig
cp "$DOTFILES_DIR/shared/git/gitconfig" ~/.gitconfig
link "$DOTFILES_DIR/shared/git/gitignore_global" ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# Homebrew
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ "$OS" = "linux" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
fi

# Shared formulae
echo "Installing shared brew formulae..."
brew_install gcc gh neovim lazygit ripgrep fd node tree-sitter-cli

# SSH + GitHub auth
source "$DOTFILES_DIR/ssh-setup.sh"

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
fi

# OS-specific setup (installs)
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

# Fonts
echo "Installing fonts..."
if [ "$OS" = "mac" ]; then
    cp -r "$DOTFILES_DIR/shared/fonts/"* ~/Library/Fonts/
else
    mkdir -p ~/.local/share/fonts
    cp -r "$DOTFILES_DIR/shared/fonts/"* ~/.local/share/fonts/
    fc-cache -fv
fi

# Configure all configs and symlinks
bash "$DOTFILES_DIR/configure.sh"

kill "$SUDO_PID" 2>/dev/null || true
echo "Done!"

if [ "$OS" = "linux" ]; then
    echo "A reboot is required to apply all changes."
    read -p "Reboot now? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo reboot
    fi
fi
