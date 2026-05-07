echo "=== Fedora Setup ==="

# Belt-and-suspenders CA repair (also called from `setup`). Cheap when healthy.
ensure_ca_trust

# RPM Fusion (free + nonfree) — needed for Discord, ffmpeg codecs, etc.
if ! rpm -q rpmfusion-free-release &>/dev/null; then
    echo "Enabling RPM Fusion free..."
    sudo dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
fi
if ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
    echo "Enabling RPM Fusion nonfree..."
    sudo dnf install -y "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
fi

# dnf-plugins-core (provides `dnf config-manager` and `dnf copr`)
dnf_install dnf-plugins-core

# Flatpak + Flathub (Fedora's stock flatpak repo lacks many apps)
dnf_install flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    sudo systemctl enable --now docker
fi

# NVIDIA drivers (skipped automatically on machines without an NVIDIA GPU)
source "$DOTFILES_DIR/linux/fedora/nvidia.sh"

# keyd (COPR — alternateved/keyd)
if ! command -v keyd &> /dev/null; then
    echo "Installing keyd..."
    sudo dnf copr enable -y alternateved/keyd
    sudo dnf install -y keyd
fi

# keyd config (caps lock -> ctrl/esc)
sudo mkdir -p /etc/keyd
sudo ln -snf "$DOTFILES_DIR/linux/shared/keyd/default.conf" /etc/keyd/default.conf
sudo ln -snf "$DOTFILES_DIR/linux/shared/keyd/dell.conf" /etc/keyd/dell.conf
sudo systemctl enable --now keyd

# DDEV (official RPM repo — write .repo file directly per DDEV's Fedora docs).
# Their hosted ddev.repo file 404s; gpgcheck=0 because signed yum repo support
# is "added in the future" per https://docs.ddev.com/...
if ! command -v ddev &> /dev/null; then
    echo "Installing DDEV..."
    sudo tee /etc/yum.repos.d/ddev.repo > /dev/null <<'EOF'
[ddev]
name=ddev
baseurl=https://pkg.ddev.com/yum/
gpgcheck=0
enabled=1
EOF
    sudo dnf install --refresh -y ddev
fi

# Ghostty (COPR scottames/ghostty per ghostty.org/docs/install/binary)
if ! command -v ghostty &> /dev/null; then
    echo "Installing Ghostty..."
    sudo dnf copr enable -y scottames/ghostty
    sudo dnf install -y ghostty
fi

# Ungoogled Chromium (COPR — wojnilowicz/ungoogled-chromium)
if ! rpm -q ungoogled-chromium &>/dev/null; then
    echo "Installing Ungoogled Chromium..."
    sudo dnf copr enable -y wojnilowicz/ungoogled-chromium
    sudo dnf install -y ungoogled-chromium
fi

# 1Password (official RPM repo)
if ! command -v 1password &> /dev/null; then
    echo "Installing 1Password..."
    sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
    sudo tee /etc/yum.repos.d/1password.repo > /dev/null <<'EOF'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF
    sudo dnf install -y 1password 1password-cli
fi

# Discord (RPM Fusion nonfree)
dnf_install discord

# Slack (Flathub — no maintained Fedora RPM repo)
if ! flatpak list 2>/dev/null | grep -q com.slack.Slack; then
    echo "Installing Slack..."
    flatpak install -y flathub com.slack.Slack
fi

# Zed (Flathub)
if ! flatpak list 2>/dev/null | grep -q dev.zed.Zed; then
    echo "Installing Zed..."
    flatpak install -y flathub dev.zed.Zed
fi

# Zen Browser (COPR sneexy/zen-browser — official binaries packaged for Fedora).
# Native (not Flatpak) so dev tooling works: localhost certs, native messaging
# hosts (1Password CLI), file:// access to project dirs.
if ! command -v zen-browser &> /dev/null; then
    echo "Installing Zen Browser..."
    sudo dnf copr enable -y sneexy/zen-browser
    sudo dnf install -y zen-browser
fi

# Tauri development libraries
dnf_install webkit2gtk4.1-devel gtk3-devel libappindicator-gtk3-devel librsvg2-devel openssl-devel

# Laravel installer (PHP + Composer come from brew)
if ! command -v laravel &> /dev/null; then
    echo "Installing Laravel installer..."
    composer global require laravel/installer
fi

# DDEV global config (sg runs command with docker group access in current session)
if command -v ddev &> /dev/null; then
    sg docker -c "ddev config global --project-tld=test"
    mkcert -install
fi

# Remove unwanted default apps
source "$DOTFILES_DIR/linux/fedora/cleanup.sh"

echo "=== Fedora setup complete ==="
