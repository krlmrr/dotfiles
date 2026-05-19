echo "=== Debian/Ubuntu Setup ==="

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
sudo ln -snf "$DOTFILES_DIR/linux/shared/keyd/dell.conf" /etc/keyd/dell.conf
sudo systemctl enable --now keyd

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

# Zed (official install script — native, not Flatpak, so the `zed` CLI lands in
# ~/.local/bin and there's no sandbox to fight for file access / project paths).
if ! command -v zed &> /dev/null; then
    echo "Installing Zed..."
    curl -f https://zed.dev/install.sh | sh
fi

# Zen Browser
if ! command -v zen-browser &> /dev/null; then
    echo "Installing Zen Browser..."
    curl -sSL https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository | sudo bash
    sudo apt install -y zen-browser
fi

# Tauri development libraries
apt_install libwebkit2gtk-4.1-dev libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev libssl-dev

# Laravel installer (PHP + Composer come from brew)
if ! command -v laravel &> /dev/null; then
    echo "Installing Laravel installer..."
    composer global require laravel/installer
fi

# Podman (Lerd's container runtime)
apt_install podman

# Lerd (podman-based Laravel local dev environment)
if ! command -v lerd &>/dev/null; then
    echo "Installing Lerd..."
    curl -fsSL https://raw.githubusercontent.com/geodro/lerd/main/install.sh | bash
fi

# Remove unwanted default apps
source "$DOTFILES_DIR/linux/deb/cleanup.sh"

echo "=== Debian/Ubuntu setup complete ==="
