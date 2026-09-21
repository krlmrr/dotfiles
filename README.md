# dotfiles

Cross-platform dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).
One repo, three machines: a MacBook Pro, a personal PC, and a TrueNAS box.

## Quick start

```bash
git clone https://github.com/krlmrr/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./bin/.local/bin/dot install
```

`dot install` is the whole install. On a fresh Mac, install the Brewfile first
(see Prerequisites), then run it.

## Prerequisites

The dotfiles are inert without the tools they set up. Install these first.

### macOS

Everything comes from [Homebrew](https://brew.sh). The manifest lives in the
`homebrew` package at `homebrew/.config/homebrew/Brewfile` —
41 formulae, 49 casks, 6 taps, including `stow` itself.

```bash
brew bundle --file=~/dotfiles/homebrew/.config/homebrew/Brewfile
```

At minimum, `dot install` itself needs:

```bash
brew install stow git zsh neovim
```

(all four are also in the Brewfile, so a `brew bundle` run covers this too).

Once the `homebrew` package is stowed, `~/.config/homebrew/Brewfile` is the
path `brew bundle --global` resolves to, so `brew bundle`, `brew bundle check`
and `brew bundle dump --global --force` all work from any directory with no
`--file`. The package also carries `trust.json`, Homebrew's record of which
non-official taps you have approved — without it a new machine refuses every
tapped formula with an `attempted to use a Downloadable without a URL!` error.

### Linux

Verified on Omarchy (Arch + Hyprland), host `omarchy`. All of these are in the
official Arch repos:

```bash
sudo pacman -S --needed stow git zsh neovim ghostty btop \
                        lazygit yazi fzf python
```

Three things are not pacman packages and install themselves:

- `herdr` — install separately; `hosts/omarchy.packages` stows its config either way.
- oh-my-zsh, into `~/.oh-my-zsh`.
- `zsh-autosuggestions` and `zsh-syntax-highlighting`, into `~/.oh-my-zsh/custom/plugins`.

Hyprland, the bar and the theme machinery come from Omarchy itself. The `hypr`,
`omarchy` and `linuxbin` packages configure those and assume an
Omarchy install, so they appear only in `hosts/omarchy.packages`.

### TrueNAS

Minimal set only:

```
git stow zsh neovim
```

Note that TrueNAS treats its OS dataset as disposable and a home directory on it
will not survive an upgrade. Put the repo and its target home on a real dataset,
or run all of this inside a jail or container rather than on the host.

## How it works

> Why Stow, if you're re-reading this in a year: the directory structure *is*
> the config. No install script to maintain, no copy step, no sync step — the
> file in `$HOME` and the file in the repo are the same file on disk.
> [TypeCraft's walkthrough](https://www.youtube.com/watch?v=NoFiYOqnC4o) is the
> short version of the idea.

A **package** is a top-level directory whose contents mirror their path under
`$HOME`. `git/.gitconfig` becomes `~/.gitconfig`. `zsh/.zshrc` becomes
`~/.zshrc`.

```bash
stow git          # link the git package into $HOME
stow -R git       # restow: remove and re-add, picks up new files
stow -D git       # unlink
stow -n -v git    # dry run, showing what would happen
```

Every package targets `$HOME` except `vscode`, which is macOS-only and targets
`~/Library/Application Support`. `dot install` handles that separately.

Before stowing, `dot install` walks every package's own directory tree and
pre-creates the matching directories under the target (`create_target_dirs`).
Without this, stow would link a missing target directory as a single symlink
back to the package directory instead of descending into it — which means
anything an app later writes under that path (Hammerspoon's `Spoons/`, herdr's
sockets and logs, Claude's `projects/`/`todos/`) would land inside the git
repo instead of in a real directory. The directory
set is derived from each package's contents at install time, not from a
hardcoded list, so it can't go stale when a package gains a new subdirectory.

**Editing a linked file edits tracked source directly.** There is no copy step
and no sync step — `~/.gitconfig` and `git/.gitconfig` are the same file on
disk. Changes show up in `git status` immediately and stay uncommitted until
you commit them.

## Which packages does a machine get?

`hosts/<hostname>.packages`, one package name per line. That file is the only
place machine-specific knowledge lives. This repo currently ships
`hosts/16-MacBook-Pro.packages`, `hosts/omarchy.packages`,
`hosts/default-linux.packages`, and `hosts/default-minimal.packages`. A machine with no file of its own falls back
to one of the two defaults depending on `uname`: Linux gets
`default-linux.packages`, anything else (including a Mac with no host file of
its own) gets `default-minimal.packages`.

## Machine-local files

These are generated per machine and must never be committed, so they are not a
stow package at all — `dot install` writes them straight to their real paths and
nothing links back into this repo:

| Path | What |
|------|------|
| `~/.config/git/identity` | `[user]` name/email, included by `.gitconfig` |
| `~/.config/jj/conf.d/00-identity.toml` | the same identity for jj |
| `~/.config/ghostty/local.conf` | optional per-machine Ghostty overrides; never created automatically |

`~/.zshrc` is stowed from `zsh/.zshrc` like any other file. Tools append to
that path — Herd rewrites `HERD_PHP_*_INI_SCAN_DIR` on every PHP version
change — so expect it to go dirty after a PHP switch, and commit or discard
as you like. The Herd block in it is guarded and derives its paths from
`$HOME`, so it is inert on a machine without Herd.

## Neovim

Two packages target the same path, `~/.config/nvim` — the path Neovim reads by
default, so no `$NVIM_APPNAME` is involved. Exactly one is ever stowed, chosen
by the host's package list:

| Package | Host | What it is |
|---------|------|------------|
| `nvim`    | macOS | the hand-rolled config, `lua/custom/plugins`, blade/PHP tooling |
| `lazyvim` | `omarchy` | LazyVim underneath, with the Omarchy theme hot-reload plugin |

Listing both on one machine is a stow conflict, which is the intended
safeguard rather than a problem to work around.

## Ghostty

One shared `ghostty/.config/ghostty/config` serves both machines. It leans on
three Ghostty behaviours rather than splitting per OS:

- `super` is an alias for `cmd`, so one keybind line works on both.
- `macos-*` keys are accepted and ignored on Linux, and `gtk-*`,
  `async-backend` and `window-theme = ghostty` are likewise inert on macOS,
  so the platform keys all live in the one file.
- `config-file` entries prefixed with `?` are skipped when the file is absent,
  and load *after* the config that names them, so they override it.

Two includes layer on top, both optional:

| Include | Provided by | Holds |
|---------|-------------|-------|
| `~/.local/state/omarchy/current/theme/ghostty.conf` | Omarchy, regenerated per theme | colours |
| `~/.config/ghostty/local.conf` | nothing — untracked, optional | per-machine overrides |

The font line lists MonoLisa first and JetBrainsMono Nerd Font second. Ghostty
skips a family that is not installed, so the Mac gets MonoLisa and Linux falls
through to JetBrains without a conditional.

## The `bin` package

`bin/.local/bin/dot` is the `dot` CLI (`dot status`, `dot pull`, `dot push`) —
stowed like any other package, so it lands on `$PATH` at `~/.local/bin/dot`
once `~/.local/bin` is on it.

## Adding a package

The directory structure *is* the configuration — there is no script to edit.

```bash
cd ~/dotfiles
mkdir -p foo/.config/foo
mv ~/.config/foo/config.toml foo/.config/foo/   # move the real file in
stow foo                                        # link it back
echo foo >> hosts/$(hostname -s).packages       # so dot install picks it up on every machine
```

The `hosts` line is the one that gets forgotten. Without it the package works
here but a fresh clone will not stow it.

One habit worth keeping:

- **`stow -n -v foo` before `stow foo`** when unsure. It prints exactly what
  would happen without touching anything.

Links are per-file, not per-directory. Editing a linked file is live — it is
the same file on disk. But *adding* a new file to a package needs `stow -R foo`
(or `dot install`) before it appears in `$HOME`.

## Fonts, wallpapers and themes

`sketchybar-app-font` ships inside the `sketchybar` package, because that is the
only thing that uses it and sketchybar is macOS-only. macOS activates it through
the symlink — no copy step needed.

FiraCode and FiraMono come from Homebrew casks rather than being vendored here,
so they stay updated and do not put ~96MB of binaries in git. MonoLisa is a paid
per-seat font and is deliberately **not** in this repo; install it by hand.

`wallpapers` is an ordinary stow package — `wallpapers/Pictures/Wallpapers/`
links per file into `~/Pictures/Wallpapers/`.

`assets/omarchy-themes/` is the exception. It is not a package; `dot install`
links the whole directory:

```
~/.config/omarchy/themes  -> ~/dotfiles/assets/omarchy-themes   (Linux only)
```

Stow is wrong for it because it descends and links each file individually.
`omarchy theme set` stages a theme with `cp -r`, which copies a per-file symlink
verbatim — a stow-relative target correct in `~/.config/omarchy/themes/<t>/`
resolves one level wrong once copied into `current/next-theme/`, so
`colors.toml` reads as missing and `omarchy-theme-set-templates` silently emits
nothing while exiting 0, losing `btop.theme`, `ghostty.conf`, `hyprland.lua` and
16 others. Linking the directory keeps the files inside real, so `cp -r` copies
content. A theme added later by `omarchy theme install` also lands in the repo
rather than outside it.

## Commands

```bash
dot status        # repo status plus this host's package list
dot pull           # pull, then restow
dot push [msg]     # stage tracked changes, commit, push

dot install                            # re-run linking; idempotent
stow -D <package>...                  # undo links for those packages
```
