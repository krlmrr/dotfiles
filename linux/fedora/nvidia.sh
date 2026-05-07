echo "=== NVIDIA Drivers ==="

if ! lspci | grep -E 'VGA|3D|Display' | grep -qi nvidia; then
    echo "No NVIDIA GPU detected, skipping."
else
    # Open kernel modules (Turing+) from RPM Fusion nonfree.
    # kernel-devel-matched ensures dev headers exist for every installed kernel so akmod can always build.
    # CUDA userspace, VA-API for hardware video decode, Vulkan for gaming/COSMIC.
    dnf_install kernel-devel-matched akmod-nvidia-open xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-cuda-libs libva-nvidia-driver libva-utils vulkan-loader

    # Force akmod to build the kernel module now so it's ready on next boot.
    # Without this, the build runs lazily and the first boot may fall back to nouveau / black screen.
    echo "Building NVIDIA kernel module (akmod) — this can take several minutes..."
    sudo akmods --force

    # nvidia-container-toolkit (Docker --gpus all). Requires Docker already installed.
    if ! rpm -q nvidia-container-toolkit &>/dev/null; then
        echo "Installing nvidia-container-toolkit..."
        ensure_ca_trust  # akmods/dnf upgrade earlier may have broken the CA bundle again
        # Write the repo file ourselves (no curl) with skip_if_unavailable=1 so a
        # transient NVIDIA repo failure can never poison other dnf operations.
        sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo > /dev/null <<'EOF'
[libnvidia-container]
name=libnvidia-container
baseurl=https://nvidia.github.io/libnvidia-container/stable/rpm/$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://nvidia.github.io/libnvidia-container/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
skip_if_unavailable=1
EOF
        if sudo dnf install -y nvidia-container-toolkit; then
            sudo nvidia-ctk runtime configure --runtime=docker
            sudo systemctl restart docker || true
        else
            echo "WARNING: nvidia-container-toolkit install failed — removing repo file so it doesn't break future dnf operations. Re-run setup once the underlying issue is resolved."
            sudo rm -f /etc/yum.repos.d/nvidia-container-toolkit.repo
        fi
    fi
fi

echo "=== NVIDIA setup complete ==="
