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

# keyd config (caps lock -> ctrl/esc)
sudo mkdir -p /etc/keyd
sudo ln -snf "$DOTFILES_DIR/linux/shared/keyd/default.conf" /etc/keyd/default.conf
sudo systemctl enable --now keyd

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

# Discord
if ! command -v discord &> /dev/null; then
    echo "Installing Discord..."
    wget -O /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
    sudo apt install -y /tmp/discord.deb
    rm /tmp/discord.deb
fi

# Slack
if ! command -v slack &> /dev/null; then
    echo "Installing Slack..."
    curl -fsSL https://packagecloud.io/slacktechnologies/slack/gpgkey | sudo gpg --dearmor --output /usr/share/keyrings/slack.gpg
    echo 'deb [signed-by=/usr/share/keyrings/slack.gpg] https://packagecloud.io/slacktechnologies/slack/debian/ jessie main' | sudo tee /etc/apt/sources.list.d/slack.list
    sudo apt update
    sudo apt install -y slack-desktop
fi

# Zed
if ! flatpak list 2>/dev/null | grep -q dev.zed.Zed; then
    echo "Installing Zed..."
    flatpak install -y flathub dev.zed.Zed
fi

# Zen Browser
if ! command -v zen-browser &> /dev/null; then
    echo "Installing Zen Browser..."
    curl -sSL https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository | sudo bash
    sudo apt install -y zen-browser
fi

# PHP / Laravel CLI
if ! command -v php &> /dev/null; then
    echo "Installing PHP / Laravel CLI..."
    /bin/bash -c "$(curl -fsSL https://php.new/install/linux)"
fi

# DDEV global config (sg runs command with docker group access in current session)
if command -v ddev &> /dev/null; then
    sg docker -c "ddev config global --project-tld=test"
fi

# Remove unwanted default apps
source "$DOTFILES_DIR/linux/deb/cleanup.sh"

echo "=== Debian/Ubuntu setup complete ==="
