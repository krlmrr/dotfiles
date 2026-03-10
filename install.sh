#!/bin/bash
set -e

# Install git if needed
if ! command -v git &> /dev/null; then
    echo "Installing git..."
    sudo apt update && sudo apt install -y git
fi

# Clone dotfiles
if [ ! -d "$HOME/Code/dotfiles" ]; then
    mkdir -p ~/Code
    git clone https://github.com/krlmrr/dotfiles.git ~/Code/dotfiles
fi

# Run setup (< /dev/tty restores terminal input for interactive prompts)
cd ~/Code/dotfiles && bash setup.sh < /dev/tty
