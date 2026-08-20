# dotfiles

macOS-only dotfiles.

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

`setup` runs the full setup chain:

1. Installs [Homebrew](https://brew.sh) + formulae (gcc, gh, neovim, lazygit, ripgrep, fd)
2. Installs [Oh My Zsh](https://ohmyz.sh) + plugins (autosuggestions, syntax-highlighting)
3. Sets zsh as default shell
4. Installs Homebrew casks (Ghostty, Arc, Zed, VS Code, OrbStack, Raycast, Slack, Discord, Figma, TablePlus, and more)
5. Configures caps lock remapping (ctrl/esc) via a LaunchDaemon (hidutil) and Hammerspoon
6. Symlinks Hammerspoon, VS Code, Sketchybar, yabai/skhd configs and starts the window-manager stack
7. Installs [Claude Code](https://claude.ai)
8. Installs fonts (FiraCode, FiraMono, MonoLisa) by copying them into `~/Library/Fonts`
9. Runs `./configure`, which symlinks the rest of the configs (zsh, git, jj, nvim, ghostty, lazygit, zed, claude skills) and generates the git/jj identity files

## Structure

```
dotfiles/
├── setup                 # Entry point
├── configure             # Symlinks/generates configs; run again standalone
├── functions.sh          # Helpers (link, brew_install, brew_install_cask)
├── install               # Bootstrap installer (curl | bash)
├── release               # Tag + trigger GitHub release Action
├── Brewfile              # Homebrew formulae + casks
├── testing/
│   └── rollback.sh       # Undo symlinks and configs
├── scripts/
│   └── ssh-setup.sh
├── zsh/
├── ghostty/
├── git/
├── nvim/
├── lazygit/
├── zed/
├── jj/
├── claude/
├── fonts/
├── wallpapers/
├── hammerspoon/
├── vscode/
├── raycast/
├── sketchybar/
├── yabai/
├── keyboard_settings/
├── memory/
└── docs/
```

## Useful Commands

```bash
# Reload .zshrc after changing aliases (it's symlinked, so edits are already live)
source ~/.zshrc

# Undo all symlinks and configs (leaves packages installed)
~/Code/dotfiles/testing/rollback.sh

# Re-run full setup
~/Code/dotfiles/setup
```
