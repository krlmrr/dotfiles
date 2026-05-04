# dotfiles

Cross-platform dotfiles for macOS and Linux (Debian/Ubuntu + Arch).

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/krlmrr/dotfiles/main/install | bash
```

Or manually:

```bash
git clone https://github.com/krlmrr/dotfiles.git ~/Code/dotfiles
cd ~/Code/dotfiles && ./setup
```

## What It Does

`setup` detects the OS and runs the appropriate setup chain:

1. Installs system packages (Linux only)
2. Installs [Homebrew](https://brew.sh) + shared formulae (gcc, gh, neovim, lazygit, ripgrep, fd)
3. Installs [Oh My Zsh](https://ohmyz.sh) + plugins (autosuggestions, syntax-highlighting)
4. Sets zsh as default shell
5. Builds `.zshrc` from shared + OS-specific aliases
6. Runs OS-specific setup (mac or linux)
7. Installs [Claude Code](https://claude.ai)
8. Symlinks shared configs (nvim, ghostty, lazygit, zed)
9. Configures git (prompts for name/email on first run)
10. Installs fonts (FiraCode, FiraMono, MonoLisa)
11. Configures COSMIC desktop (if detected)

## Structure

```
dotfiles/
├── setup                 # Entry point
├── buildzshrc            # Rebuild .zshrc without full setup
├── testing/
│   └── rollback.sh       # Undo symlinks and configs
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
    │   ├── setup.sh      # Docker, keyd, DDEV, Ghostty, Chromium, Zen, 1Password, PHP
    │   └── cleanup.sh    # Remove unwanted default apps
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

Configures caps lock remapping (ctrl/esc) via a LaunchDaemon (hidutil) and Hammerspoon.

### Linux (Debian/Ubuntu)

Installs Docker, DDEV, Ghostty (PPA), Ungoogled Chromium (PPA), Zen Browser, 1Password, keyd, and PHP/Laravel CLI.

Configures keyd for caps lock remapping (ctrl/esc), udev rules for Keychron Q8 (Via), and COSMIC desktop (dock, panel, theme, mouse, shortcuts).

### Linux (Arch)

Installs Docker, keyd, DDEV (AUR), Hyprland, Waybar, Rofi, Mako, and SDDM.

## Useful Commands

```bash
# Rebuild .zshrc after changing aliases
~/Code/dotfiles/buildzshrc && source ~/.zshrc

# Undo all symlinks and configs (leaves packages installed)
~/Code/dotfiles/testing/rollback.sh

# Re-run full setup
~/Code/dotfiles/setup
```
