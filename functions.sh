#!/bin/bash

# Remove existing and symlink
link() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "link() error: missing argument" >&2
        return 1
    fi
    mkdir -p "$(dirname "$2")"
    rm -rf "$2"
    ln -snf "$1" "$2"
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
