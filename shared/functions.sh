#!/bin/bash

# Remove existing and symlink
link() {
    rm -rf "$2"
    ln -sf "$1" "$2"
}

# Detect OS
if [[ "$(uname)" == "Darwin" ]]; then
    readonly OS="mac"
else
    readonly OS="linux"
fi

# Detect Linux distro
if [ "$OS" = "linux" ]; then
    if command -v pacman &> /dev/null; then
        readonly DISTRO="arch"
        readonly PKG="pacman -S --noconfirm"
        readonly PKG_UPDATE="pacman -Syu --noconfirm"
    elif command -v apt &> /dev/null; then
        readonly DISTRO="deb"
        readonly PKG="apt install -y"
        readonly PKG_UPDATE="apt update"
    else
        echo "Unsupported distro"
        exit 1
    fi
fi
