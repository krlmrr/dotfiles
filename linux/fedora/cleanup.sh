echo "=== Cleaning up default apps ==="

# Remove Firefox (using Zen instead)
if rpm -q firefox &>/dev/null; then
    echo "Removing Firefox..."
    sudo dnf remove -y firefox
fi

echo "=== Cleanup complete ==="
