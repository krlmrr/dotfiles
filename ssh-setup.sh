#!/bin/bash
# Sets up SSH key and config

# Ensure ~/.ssh exists with correct permissions
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Set TERM for remote SSH sessions (Ghostty terminfo isn't available on most servers)
if ! grep -q 'SetEnv TERM=xterm-256color' ~/.ssh/config 2>/dev/null; then
    echo "" >> ~/.ssh/config
    echo "Host *" >> ~/.ssh/config
    echo "  SetEnv TERM=xterm-256color" >> ~/.ssh/config
    chmod 600 ~/.ssh/config
fi

# Add GitHub to known_hosts first to prevent host key prompts
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null

if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    # Generate SSH key if none exists
    SSH_KEY="$HOME/.ssh/id_ed25519"
    if [ ! -f "$SSH_KEY" ]; then
        echo "Generating SSH key..."
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -q
    fi

    echo ""
    echo "Key title: $(hostname)"
    echo ""
    echo "Your public key:"
    echo ""
    cat "$SSH_KEY.pub"
    echo ""
    echo "Add it here: https://github.com/settings/ssh/new"
    echo ""
    read -p "Press Enter after you've added the key to GitHub..."

    # Verify
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "GitHub SSH configured successfully!"
    else
        echo "Warning: SSH authentication failed. Check your key on GitHub and try again."
    fi
else
    echo "GitHub SSH already configured."
fi
