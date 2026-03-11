#!/bin/bash

# Remove existing and symlink
link() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "link() error: missing argument" >&2
        return 1
    fi
    rm -rf "$2"
    ln -snf "$1" "$2"
}

# Append a line to a file
append() {
    echo "$1" >> "$2"
}

# Install only missing brew formulae
brew_install() {
    local missing=()
    for pkg in "$@"; do
        if ! brew list "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Installing: ${missing[*]}"
        brew install "${missing[@]}"
    fi
}

# Install only missing brew casks
brew_install_cask() {
    local missing=()
    for pkg in "$@"; do
        if ! brew list --cask "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Installing casks: ${missing[*]}"
        brew install --cask "${missing[@]}"
    fi
}

# Install only missing pacman packages
pacman_install() {
    local missing=()
    for pkg in "$@"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Installing: ${missing[*]}"
        sudo pacman -S --noconfirm "${missing[@]}"
    fi
}

# Install only missing apt packages
apt_install() {
    local missing=()
    for pkg in "$@"; do
        if ! dpkg -s "$pkg" &>/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Installing: ${missing[*]}"
        sudo apt install -y "${missing[@]}"
    fi
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
        readonly PKG_UPGRADE="apt upgrade -y"
    else
        echo "Unsupported distro"
        exit 1
    fi
fi
