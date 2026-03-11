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
brew_install gcc gh neovim lazygit ripgrep fd

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
if [ -d "$HOME/.var/app/dev.zed.Zed" ]; then
    link "$DOTFILES_DIR/shared/zed/settings.json" ~/.var/app/dev.zed.Zed/config/zed/settings.json
    link "$DOTFILES_DIR/shared/zed/themes" ~/.var/app/dev.zed.Zed/config/zed/themes
    link "$DOTFILES_DIR/linux/shared/zed-keymap.json" ~/.var/app/dev.zed.Zed/config/zed/keymap.json
else
    link "$DOTFILES_DIR/shared/zed" ~/.config/zed
fi

# Zen Browser user.js
echo "Configuring Zen Browser..."
zen_launch() {
    if flatpak list 2>/dev/null | grep -q app.zen_browser.zen; then
        flatpak run app.zen_browser.zen &>/dev/null &
    elif command -v zen-browser &>/dev/null; then
        zen-browser &>/dev/null &
    else
        return 1
    fi
    ZEN_PID=$!
    # Wait for profile to be created (up to 15s)
    for i in $(seq 1 15); do
        [ -n "$(zen_root)" ] && ls "$(zen_root)"/*.*/ &>/dev/null && break
        sleep 1
    done
    kill "$ZEN_PID" 2>/dev/null || true
    wait "$ZEN_PID" 2>/dev/null || true
}

zen_root() {
    if [ -d "$HOME/.var/app/app.zen_browser.zen/.zen" ]; then
        echo "$HOME/.var/app/app.zen_browser.zen/.zen"
    elif [ -d "$HOME/.zen" ]; then
        echo "$HOME/.zen"
    fi
}

ZEN_ROOT="$(zen_root)"
if [ -z "$ZEN_ROOT" ] || ! ls "$ZEN_ROOT"/*.*/ &>/dev/null; then
    echo "Opening Zen to create profile..."
    zen_launch || true
    ZEN_ROOT="$(zen_root)"
fi
if [ -n "$ZEN_ROOT" ]; then
    for profile_dir in "$ZEN_ROOT"/*.*/; do
        [ -d "$profile_dir" ] || continue
        cp "$DOTFILES_DIR/shared/zen/user.js" "$profile_dir/user.js"
    done
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
