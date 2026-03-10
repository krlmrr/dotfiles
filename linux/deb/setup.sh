echo "=== Debian/Ubuntu Setup ==="

# Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
fi

# keyd
if ! command -v keyd &> /dev/null; then
    echo "Installing keyd..."
    sudo add-apt-repository -y ppa:keyd-team/ppa
    sudo apt update
    sudo apt install -y keyd
fi

# DDEV
if ! command -v ddev &> /dev/null; then
    echo "Installing DDEV..."
    curl -fsSL https://pkg.ddev.com/apt/gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/ddev.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/ddev.gpg] https://pkg.ddev.com/apt/ * *" | sudo tee /etc/apt/sources.list.d/ddev.list
    sudo apt update
    sudo apt install -y ddev
fi

# Ghostty
if ! command -v ghostty &> /dev/null; then
    echo "Installing Ghostty..."
    sudo add-apt-repository -y ppa:mkasberg/ghostty-ubuntu
    sudo apt update
    sudo apt install -y ghostty
fi

# Ungoogled Chromium
if ! command -v chromium &> /dev/null; then
    echo "Installing Ungoogled Chromium..."
    sudo add-apt-repository -y ppa:xtradeb/apps
    sudo apt update
    sudo apt install -y chromium
fi

# 1Password
if ! command -v 1password &> /dev/null; then
    echo "Installing 1Password..."
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
    sudo apt update
    sudo apt install -y 1password
fi

# PHP / Laravel CLI
if ! command -v php &> /dev/null; then
    echo "Installing PHP / Laravel CLI..."
    /bin/bash -c "$(curl -fsSL https://php.new/install/linux)"
fi

# DDEV global config
sg docker -c "ddev config global --project-tld=test"

# Remove unwanted default apps
source "$DOTFILES_DIR/linux/deb/cleanup.sh"

echo "=== Debian/Ubuntu setup complete ==="
