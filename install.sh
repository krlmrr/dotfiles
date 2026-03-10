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

# Run setup
cd ~/Code/dotfiles && bash setup.sh
