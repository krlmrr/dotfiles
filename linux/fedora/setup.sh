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

# Zed (official install script — native, not Flatpak, so the `zed` CLI lands in
# ~/.local/bin and there's no sandbox to fight for file access / project paths).
if ! command -v zed &> /dev/null; then
    echo "Installing Zed..."
    curl -f https://zed.dev/install.sh | sh
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

# Podman (Lerd's container runtime)
dnf_install podman

# Lerd (podman-based Laravel local dev environment)
if ! command -v lerd &>/dev/null; then
    echo "Installing Lerd..."
    curl -fsSL https://raw.githubusercontent.com/geodro/lerd/main/install.sh | bash
fi

# cosmic-greeter wallpaper sync is installed from linux/setup.sh after the
# COSMIC config copy — it does an initial sync that needs ~/.config/cosmic
# already populated, otherwise the first run is a silent no-op.

# Remove unwanted default apps
source "$DOTFILES_DIR/linux/fedora/cleanup.sh"

echo "=== Fedora setup complete ==="
