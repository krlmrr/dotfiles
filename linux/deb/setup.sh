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

# PHP / Laravel CLI
if ! command -v php &> /dev/null; then
    echo "Installing PHP / Laravel CLI..."
    /bin/bash -c "$(curl -fsSL https://php.new/install/linux)"
fi

# DDEV global config
ddev config global --project-tld=test

echo "=== Debian/Ubuntu setup complete ==="
