# Flatten dotfiles to macOS-only

**Date:** 2026-07-31
**Status:** Approved

## Goal

The user has abandoned the Linux route. Flatten the cross-platform dotfiles
repo into a macOS-only repo: delete all Linux support, dissolve the
`shared/` + `mac/` split into a single flat layout at the repo root, and
collapse the OS-branching build indirection now that there is only one OS.

## Decisions (locked during brainstorming)

1. **Structure:** Full flat layout — dissolve both `shared/` and `mac/`;
   everything moves to the repo root.
2. **Zen Browser:** Drop entirely (the `configure` block only targeted
   Linux/Flatpak profile paths; user does not need it on macOS).
3. **Build scripts:** Collapse fully — bake OS-specific lines into static
   config and symlink directly; eliminate the build scripts.
4. **zshrc handling:** `~/.zshrc` becomes a symlink to `zsh/zshrc`, which
   ends with `source "$HOME/Code/dotfiles/zsh/aliases.sh"`. (Approved judgment
   call — the repo already hardcodes `~/Code/dotfiles` elsewhere.)
5. **mac/setup.sh:** Fold inline into the root `setup` script rather than
   keeping a separate file. (Approved judgment call.)

## Target directory structure

`shared/` and `mac/` dissolve; `linux/` is deleted. Files move via `git mv`
to preserve history.

```
dotfiles/
├── setup, configure, install, release      # entry scripts (root, kept)
├── functions.sh                            # was shared/functions.sh, stripped to mac-only
├── Brewfile                                # shared/Brewfile + mac/Brewfile merged
├── CapsLockToControl.plist, tcc-cleanup.sh # was mac/
├── zed-keymap.json                         # was mac/
├── zsh/        (zshrc + aliases.sh)         # shared/zsh + mac/zsh merged; build.sh deleted
├── ghostty/    (config + themes/)           # mac lines baked into static config
├── nvim/ lazygit/ zed/ git/ jj/ claude/ fonts/ wallpapers/   # from shared/
├── hammerspoon/ vscode/ phpstorm/ raycast/ sketchybar/ yabai/ keyboard_settings/  # from mac/
├── memory/ docs/ testing/ scripts/ .github/ .claude/         # unchanged
```

### Deleted outright

- `linux/` (entire tree)
- `shared/zen/`
- root `cleanup.sh` symlink (points to `linux/deb/cleanup.sh`)
- `buildghostty`, `buildzshrc`
- `shared/ghostty/build.sh`, `shared/zsh/build.sh`
- `mac/setup.sh` (folded into `setup`)

## Build collapse

### Ghostty

Bake the seven mac-only `append` lines from `shared/ghostty/build.sh` into a
static `ghostty/config`:

```
macos-titlebar-proxy-icon = hidden
font-size = 18
window-padding-y = 8,0
window-padding-x = 8,8
macos-option-as-alt = true
keybind = cmd+shift+h=goto_split:left
keybind = cmd+shift+l=goto_split:right
```

`configure` symlinks:
- `ghostty/config` → `~/.config/ghostty/config`
- `ghostty/config` → `~/Library/Application Support/com.mitchellh.ghostty/config`
- `ghostty/themes` → both `themes/` locations

Delete `buildghostty` and `shared/ghostty/build.sh`. Ghostty edits become live
(symlinked), per the delivery-mode table.

### zsh

- `~/.zshrc` becomes a symlink → `zsh/zshrc`.
- `zsh/zshrc` (was `shared/zsh/zshrc`): remove the `Homebrew (Linux)` block
  (lines 20–24); append `source "$HOME/Code/dotfiles/zsh/aliases.sh"` at the end.
- Merge `mac/zsh/aliases.sh` content into `zsh/aliases.sh` (was
  `shared/zsh/aliases.sh`). One aliases file, no OS split.
- Fix hardcoded paths inside `zsh/aliases.sh`:
  - `sourcez` → `source ~/.zshrc` (no build step anymore).
  - `brewup` → `sudo bash ~/Code/dotfiles/tcc-cleanup.sh` (flat path).
- Delete `buildzshrc` and `shared/zsh/build.sh`.

## Script simplification

### functions.sh

Keep: `link()`, `brew_install()`, `brew_install_cask()`.
Drop: `$OS`/`$DISTRO`/`$PKG`/`$PKG_UPDATE`/`$PKG_UPGRADE` detection,
`apt_install`, `pacman_install`, `dnf_install`, `ensure_ca_trust`, `append()`.

### setup

- Drop the "Install core system packages (Linux)" block.
- Drop the linuxbrew branch in the Homebrew install.
- Drop the reboot prompt at the end.
- Remove every `if [ "$OS" = ... ]` branch; keep only the mac path.
- Fold `mac/setup.sh` contents inline (taps, Brewfile bundle, CapsLock
  LaunchDaemon, hammerspoon, vscode, sketchybar, yabai/skhd, sudoers).
- Point `brew bundle` at the merged root `Brewfile`.
- Fonts: keep only the macOS `~/Library/Fonts` flatten branch.
- Replace the `getent passwd`-based default-shell detection (Linux-only) with
  a macOS-safe form (e.g. compare against `$SHELL` / `dscl . -read`), still
  guarded by the `/etc/shells` check.

### configure

- Remove all `$OS` branches; the mac path always runs:
  - lazygit → `~/Library/Application Support/lazygit`
  - zed keymap → `zed-keymap.json`
  - hammerspoon, vscode, phpstorm links always run
- **Delete the entire Zen Browser block** (user.js deploy + mkcert certutil import).
- Repoint every `shared/…` and `mac/…` path to the flat root.

### install

- Drop the Linux `elif` git-install branch; keep the macOS xcode-select path.

## Docs & metadata

- **README.md:** rewrite for macOS-only — new tagline, new structure tree,
  remove all Platform Details / Linux sections, update "What It Does" (no OS
  detection, no COSMIC), update Useful Commands (no `buildzshrc`).
- **CLAUDE.md:** rewrite — remove Linux from the intro, script chain, directory
  structure, and conventions; update the delivery-mode table (ghostty and zsh
  move from "Built" to "Symlinked"; drop Linux/COSMIC rows); update key aliases
  (drop the Linux `a = ddev artisan` note).
- **.gitignore:** repoint `shared/nvim/lazy-lock.json` → `nvim/lazy-lock.json`,
  `shared/zed/prompts/` → `zed/prompts/`, `shared/lazygit/state.yml` →
  `lazygit/state.yml`.
- **memory/:** review entries describing the shared/mac/linux split and update
  any that would go stale.
- **testing/rollback.sh:** remove the "Flatpak Zed symlinks" block (lines
  16–19) and the "arch-specific symlinks" block (lines 32–39); update the final
  note that mentions `apt`. Optionally also remove the Application Support
  ghostty config symlink alongside `~/.config/ghostty`.

## Not touched

`release`, `.github/workflows`, `scripts/ssh-setup.sh`, `phpantom_lsp`, and the
*contents* of all nvim/zed/hammerspoon/vscode/etc. config — only their
locations change.

## Verification

Run `./setup` behavior can't be fully exercised without a fresh Mac, so verify:
- `bash -n` on every modified shell script (setup, configure, install,
  functions.sh) — no syntax errors.
- `./configure` runs clean on the current Mac and produces the expected
  symlinks (`~/.zshrc`, `~/.config/ghostty/config`, `~/.config/nvim`, etc.).
- `grep -rn 'shared/\|linux/\|\$OS\|\$DISTRO' setup configure install functions.sh`
  returns nothing.
- `~/.zshrc` sources cleanly (`zsh -ic 'exit'`).
- `testing/rollback.sh` still references valid paths.
```
## Amendments (2026-08-20)

6. **Branch:** work directly on `main` in small revertable commits, rather than
   in a worktree. The July worktree (`macos-only-dotfiles-dcf0a3`) is a detached
   HEAD predating ~20 commits and is abandoned; delete it.
7. **`.gitconfig` becomes a symlink too.** The spec left it as a one-shot `cp`,
   because `configure` runs `git config --global user.name/user.email` and a
   symlinked `~/.gitconfig` would write those into the repo. Resolve it the same
   way `configure` already resolves jj: symlink the tracked `git/gitconfig`, add
   an `[include]` for a generated `~/.config/git/identity`, and write the
   identity with `git config --file` so nothing lands in the repo.
8. **Drift since the spec:** `mac/prune-login-items.sh` and
   `mac/sketchybar/helpers/*` were added and must be included in the moves.
   `mac/phpstorm/` was deleted and must NOT be recreated despite appearing in
   the spec's target tree.
