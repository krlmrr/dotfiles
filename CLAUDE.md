# Dotfiles

macOS-only dotfiles.

## Memory

This project's memory lives in `./memory/` at the repo root. Read `./memory/MEMORY.md` for the index and the linked files for context. When you would normally write auto-memory to `~/.claude/projects/.../memory/`, write it to `./memory/` instead — that's the only place memory for this project belongs.

## Architecture

`setup` is the entry point. It sources `functions.sh` which provides:
- `link()` — removes target and creates symlink
- `brew_install()` — installs only missing brew formulae
- `brew_install_cask()` — installs only missing brew casks

All child scripts are `source`d (not `bash`d) so they share the same process, variables, and sudo session.

## Script Chain

```
setup (entry point)
├── functions.sh (sourced for helpers)
│   (mac setup — casks, hammerspoon, vscode, sketchybar, yabai, fonts — runs inline)
└── configure (run at the end; symlinks/generates all configs)
```

## Directory Structure

Flat at the repo root: `zsh/ ghostty/ git/ nvim/ lazygit/ zed/ jj/ claude/ fonts/ wallpapers/ hammerspoon/ vscode/ raycast/ sketchybar/ yabai/ keyboard_settings/ memory/ docs/ testing/ scripts/`, plus root files `setup configure install release Brewfile functions.sh CapsLockToControl.plist tcc-cleanup.sh prune-login-items.sh zed-keymap.json`.

## Config delivery: built vs symlinked vs copied

Three delivery modes. **Editing the source isn't always enough — built and copied configs need a rebuild step.** Always check this table before editing a source file:

| Mode | After editing source | Examples |
| --- | --- | --- |
| **Symlinked** | Live — change is immediate | `.zshrc`, ghostty config + `themes/` (both `~/.config/ghostty` and the macOS app-support location), `.gitconfig`, `gitignore_global`, nvim, lazygit, zed (`settings.json`, `themes/`, `keymap.json`), jj `config.toml`, claude skills, hammerspoon, vscode, sketchybar, yabai |
| **Copied (one-shot)** | Re-run `./configure` (or `./setup`, which calls it) | fonts — `setup` flattens `.ttf`/`.otf` files out of their per-family dirs into `~/Library/Fonts`, because macOS `fontd` only activates fonts placed directly there, not in subfolders |
| **Generated, never committed** | Re-run `./configure` | `~/.config/git/identity` (holds `user.name`/`user.email`; `[include]`d by the symlinked `git/gitconfig`, since `~/.gitconfig` itself is now a symlink into the repo and `git config --global` would otherwise write straight into tracked history), `~/.config/jj/conf.d/00-identity.toml` (same pattern, for jj) |

**Rule of thumb:** if `~/.config/foo` is a regular file (not a symlink), it's one of the two exceptions above — find the script that produces it before editing.

## Conventions

- `source` not `bash` for child scripts sourced by `setup` (shares the sudo session)
- Caps lock remapping: LaunchDaemon (hidutil) + Hammerspoon

## Key Aliases

- `a` = `php artisan` (uses Herd)
- `brewup` upgrades everything, reloads yabai's scripting addition and cleans TCC if yabai itself was upgraded, always runs `prune-login-items.sh` afterward, and relaunches Raycast (`open -gj -a Raycast`, hidden/no-focus-steal) only if the Raycast cask actually changed — restoring whatever app had focus beforehand

## Gotchas

- `zsh/aliases.sh` defines `alias test="clear && a test"` (deliberate — `test` running the Laravel suite via `php artisan test` is intentional and must NOT be changed). This shadows the `test` builtin in any zsh session that sources it: a script or verification command using `test -f foo` silently becomes `clear && php artisan test`, prints "Could not open input file: artisan", and reports false results. Scripts that get sourced into an interactive zsh (rather than run with `bash`/`sh`) should use `[ -f ... ]` instead of `test`, or `unalias test` first.

## Releases

Push a tag to trigger a GitHub Action that creates a release:
```bash
./release <next-version>
```

Uses semver. Check the latest tag with `git tag --sort=-v:refname | head -1` and bump accordingly. Always run the release script after pushing commits.

## Testing

Run `./setup` on a fresh install. Use `./testing/rollback.sh` to undo symlinks/configs without removing packages, then re-run setup.
