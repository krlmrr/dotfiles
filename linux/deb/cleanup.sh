echo "=== Cleaning up default apps ==="

# Remove Firefox (using Zen instead)
if dpkg -l firefox &> /dev/null; then
    echo "Removing Firefox..."
    sudo apt purge -y firefox
    sudo apt autoremove -y
fi

echo "=== Cleanup complete ==="
