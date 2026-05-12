echo "=== Cleaning up default apps ==="

# Remove Firefox (using Zen instead)
if rpm -q firefox &>/dev/null; then
    echo "Removing Firefox..."
    sudo dnf remove -y firefox
fi

# Remove COSMIC Text Editor (using Zed/nvim instead)
if rpm -q cosmic-edit &>/dev/null; then
    echo "Removing COSMIC Text Editor..."
    sudo dnf remove -y cosmic-edit
fi

# Remove COSMIC Terminal (using Ghostty instead; reinstall ad-hoc if Ghostty breaks)
if rpm -q cosmic-term &>/dev/null; then
    echo "Removing COSMIC Terminal..."
    sudo dnf remove -y cosmic-term
fi

# Remove Nheko (Matrix chat client — not used)
if rpm -q nheko &>/dev/null; then
    echo "Removing Nheko..."
    sudo dnf remove -y nheko
fi

echo "=== Cleanup complete ==="
