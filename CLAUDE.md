# Dotfiles

Cross-platform dotfiles for macOS and Linux (Debian/Ubuntu + Arch).

## Architecture

`setup.sh` is the entry point. It sources `shared/functions.sh` which provides:
- `link()` — removes target and creates symlink
- `$OS` — "mac" or "linux"
- `$DISTRO` — "deb" or "arch" (linux only)
- `$PKG` / `$PKG_UPDATE` — package manager commands (linux only)

All child scripts are `source`d (not `bash`d) so they share the same process, variables, and sudo session.

## Script Chain

```
setup.sh (entry point)
├── shared/functions.sh (sourced for helpers/constants)
├── buildzshrc.sh → shared/zsh/build.sh (builds .zshrc from parts)
├── mac/setup.sh (sourced on mac)
└── linux/setup.sh (sourced on linux)
    ├── linux/deb/setup.sh (sourced on debian/ubuntu)
    │   └── linux/deb/cleanup.sh (sourced, removes unwanted apps)
    └── linux/arch/setup.sh (sourced on arch)
```

## Directory Structure

- `shared/` — cross-platform configs (nvim, ghostty, lazygit, zed, zsh, git, fonts, wallpapers)
- `mac/` — macOS-specific (hammerspoon, vscode, phpstorm, zed keymap, zsh aliases)
- `linux/` — all Linux stuff
  - `linux/shared/` — shared across linux distros (zsh aliases)
  - `linux/deb/` — Debian/Ubuntu specific (setup + cleanup scripts)
  - `linux/arch/` — Arch specific (setup script + hypr, waybar, rofi, mako, sddm configs)

## Conventions

- Mac is the source of truth for shared configs
- Configs are symlinked, `.gitconfig` is copied (to avoid repo pollution from `git config --global`)
- `.zshrc` is built by concatenating: `shared/zsh/zshrc` + `shared/zsh/aliases.sh` + OS-specific aliases
- Use `buildzshrc.sh` to rebuild `.zshrc` without running full setup
- System packages install before brew (zsh must exist before oh-my-zsh)
- `source` not `bash` for child scripts (shares sudo session)

## Key Aliases

- Mac: `a` = `php artisan` (uses Herd)
- Linux: `a` = `ddev artisan` (uses DDEV/Docker)
- `brewup` differs per OS (mac reopens Raycast after upgrade)

## Releases

Push a tag to trigger a GitHub Action that creates a release:
```bash
bash release.sh 1.0.11
```

Uses semver. Check the latest tag with `git tag --sort=-v:refname | head -1` and bump accordingly. Always run the release script after pushing commits.

## Testing

Run `bash setup.sh` on a fresh install. Use `bash rollback.sh` to undo symlinks/configs without removing packages, then re-run setup.
