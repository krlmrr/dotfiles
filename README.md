# dotfiles

Cross-platform dotfiles for macOS and Linux (Debian/Ubuntu + Arch).

## Quick Start

```bash
unzip dotfiles-main.zip && cd dotfiles-main && bash setup.sh
```

## What It Does

`setup.sh` detects the OS and runs the appropriate setup chain:

1. Installs system packages (Linux only)
2. Installs [Homebrew](https://brew.sh) + shared formulae (gh, neovim, lazygit, ripgrep, fd)
3. Installs [Oh My Zsh](https://ohmyz.sh) + plugins (autosuggestions, syntax-highlighting)
4. Sets zsh as default shell
5. Builds `.zshrc` from shared + OS-specific aliases
6. Runs OS-specific setup (mac or linux)
7. Symlinks shared configs (nvim, ghostty, lazygit, zed)
8. Configures git (prompts for name/email on first run)
9. Installs fonts (FiraCode, FiraMono, MonoLisa)

## Structure

```
dotfiles/
├── setup.sh              # Entry point
├── buildzshrc.sh         # Rebuild .zshrc without full setup
├── rollback.sh           # Undo symlinks and configs
├── shared/               # Cross-platform
│   ├── functions.sh      # Helpers (link, OS/distro detection)
│   ├── nvim/
│   ├── ghostty/
│   ├── lazygit/
│   ├── zed/
│   ├── zsh/
│   ├── git/
│   ├── fonts/
│   └── wallpapers/
├── mac/                  # macOS-specific
│   ├── setup.sh          # Casks, hammerspoon, vscode, phpstorm
│   ├── zsh/
│   ├── hammerspoon/
│   ├── vscode/
│   ├── phpstorm/
│   └── zed-keymap.json
└── linux/                # Linux-specific
    ├── setup.sh          # Shared linux (brew formulae, keyd, udev)
    ├── shared/
    │   └── zsh/
    ├── deb/
    │   └── setup.sh      # Docker, keyd, DDEV, Ghostty, Chromium, PHP
    └── arch/
        ├── setup.sh      # Docker, keyd, Hyprland, SDDM
        ├── hypr/
        ├── waybar/
        ├── rofi/
        ├── mako/
        └── sddm/
```

## Platform Details

### macOS

Installs apps via Homebrew casks: Ghostty, Arc, Zed, VS Code, OrbStack, Raycast, Slack, Discord, Figma, TablePlus, and more.

Configures Hammerspoon for caps lock remapping (ctrl/esc).

### Linux (Debian/Ubuntu)

Installs Docker, DDEV, Ghostty (PPA), Ungoogled Chromium (PPA), keyd, and PHP/Laravel CLI.

Configures keyd for caps lock remapping (ctrl/esc) and udev rules for Keychron Q8 (Via).

### Linux (Arch)

Installs Docker, keyd, DDEV (AUR), Hyprland, Waybar, Rofi, Mako, and SDDM.

## Useful Commands

```bash
# Rebuild .zshrc after changing aliases
bash ~/Code/dotfiles/buildzshrc.sh && source ~/.zshrc

# Undo all symlinks and configs (leaves packages installed)
bash ~/Code/dotfiles/rollback.sh

# Re-run full setup
bash ~/Code/dotfiles/setup.sh
```
