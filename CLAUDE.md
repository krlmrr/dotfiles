# Dotfiles

Cross-platform dotfiles for macOS and Linux (Debian/Ubuntu + Arch + Fedora).

## Architecture

`setup` is the entry point. It sources `shared/functions.sh` which provides:
- `link()` — removes target and creates symlink
- `$OS` — "mac" or "linux"
- `$DISTRO` — "deb", "arch", or "fedora" (linux only)
- `$PKG` / `$PKG_UPDATE` — package manager commands (linux only)

All child scripts are `source`d (not `bash`d) so they share the same process, variables, and sudo session.

## Script Chain

```
setup (entry point)
├── shared/functions.sh (sourced for helpers/constants)
├── buildzshrc → shared/zsh/build.sh (builds .zshrc from parts)
├── mac/setup.sh (sourced on mac)
└── linux/setup.sh (sourced on linux)
    ├── linux/deb/setup.sh (sourced on debian/ubuntu)
    │   └── linux/deb/cleanup.sh (sourced, removes unwanted apps)
    ├── linux/arch/setup.sh (sourced on arch)
    └── linux/fedora/setup.sh (sourced on fedora)
        └── linux/fedora/cleanup.sh (sourced, removes unwanted apps)
```

## Directory Structure

- `shared/` — cross-platform configs (nvim, ghostty, lazygit, zed, zsh, git, fonts, wallpapers)
- `mac/` — macOS-specific (hammerspoon, vscode, phpstorm, zed keymap, zsh aliases)
- `linux/` — all Linux stuff
  - `linux/shared/` — shared across linux distros (zsh aliases, keyd config, COSMIC desktop configs, zed keymap)
  - `linux/deb/` — Debian/Ubuntu specific (setup + cleanup scripts)
  - `linux/arch/` — Arch specific (setup script + hypr, waybar, rofi, mako, sddm configs)
  - `linux/fedora/` — Fedora specific (setup + cleanup scripts; uses COSMIC like deb)

## Config delivery: built vs symlinked vs copied

Three delivery modes. **Editing the source isn't always enough — built and copied configs need a rebuild step.** Always check this table before editing a source file:

| Mode | After editing source | Examples |
| --- | --- | --- |
| **Symlinked** | Live — change is immediate | nvim, lazygit, zed, ghostty `themes/`, claude skills, `gitignore_global`, all `mac/*` configs (hammerspoon, vscode, sketchybar, yabai, phpstorm), arch `hypr/waybar/rofi/mako`, keyd |
| **Built** | Run the build script | `.zshrc` → `./buildzshrc` (concatenates `shared/zsh/zshrc` + `aliases.sh` + OS-specific aliases). `~/.config/ghostty/config` → `./buildghostty` (copies `shared/ghostty/config`, then `append`s OS-specific lines). |
| **Copied (one-shot)** | Re-run `./configure` (or the step that copies it) | `.gitconfig` (copied to avoid `git config --global` polluting the repo), COSMIC `~/.config/cosmic/*` (COSMIC rewrites its own files; `cp -a --force` from `linux/shared/cosmic/`), fonts, Zen `user.js` (Zen ignores symlinks) |

**Rule of thumb:** if `~/.config/foo` is a regular file (not a symlink), it's built or copied — find the script that produces it before editing. For Ghostty specifically, OS-specific overrides go in `shared/ghostty/build.sh` (the `mac` / `linux` branches use `append`), not in the source `config` file.

## Conventions

- Mac is the source of truth for shared configs
- System packages install before brew (zsh must exist before oh-my-zsh)
- `source` not `bash` for child scripts (shares sudo session)
- Caps lock remapping: keyd on Linux (symlinked config), LaunchDaemon + Hammerspoon on Mac

## Key Aliases

- Mac: `a` = `php artisan` (uses Herd)
- Linux: `a` = `ddev artisan` (uses DDEV/Docker)
- `brewup` differs per OS (mac reopens Raycast after upgrade)

## Releases

Push a tag to trigger a GitHub Action that creates a release:
```bash
./release <next-version>
```

Uses semver. Check the latest tag with `git tag --sort=-v:refname | head -1` and bump accordingly. Always run the release script after pushing commits.

## Testing

Run `./setup` on a fresh install. Use `./testing/rollback.sh` to undo symlinks/configs without removing packages, then re-run setup.
