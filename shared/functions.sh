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

# Ensure /etc/pki/tls/certs/ca-bundle.crt exists. On Fedora 44 we've seen this
# symlink go missing while the source PEM at /etc/pki/ca-trust/extracted/pem/
# is intact — `update-ca-trust extract` doesn't recreate it. dnf's libcurl
# refuses to load trust anchors from the missing path and every https repo
# fails with "Curl error (77): Problem with the SSL CA cert".
# Always-run + idempotent. Cheap to invoke before any dnf-over-https operation.
ensure_ca_trust() {
    [ "$DISTRO" = "fedora" ] || return 0
    local src=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
    local dst=/etc/pki/tls/certs/ca-bundle.crt
    sudo update-ca-trust extract 2>/dev/null
    # Create the symlink directly if extract didn't do it (F44 quirk).
    if [ ! -e "$dst" ] && [ -e "$src" ]; then
        sudo ln -sf "$src" "$dst"
    fi
    # Last resort: source PEM itself is missing — reinstall ca-certificates.
    if [ ! -e "$dst" ]; then
        echo "CA bundle still missing — reinstalling ca-certificates..."
        sudo dnf reinstall -y ca-certificates
        sudo update-ca-trust extract
        [ ! -e "$dst" ] && [ -e "$src" ] && sudo ln -sf "$src" "$dst"
    fi
}

# Install only missing dnf packages
dnf_install() {
    local missing=()
    for pkg in "$@"; do
        if ! rpm -q "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Installing: ${missing[*]}"
        sudo dnf install -y "${missing[@]}"
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
    elif command -v dnf &> /dev/null; then
        readonly DISTRO="fedora"
        readonly PKG="dnf install -y"
        readonly PKG_UPDATE="dnf upgrade -y"
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
