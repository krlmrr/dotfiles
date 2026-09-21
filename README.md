# dotfiles

Cross-platform dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).
One repo, three machines: a MacBook Pro, a personal PC, and a TrueNAS box.

## Quick start

```bash
git clone https://github.com/krlmrr/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./bootstrap
```

`bootstrap` is the whole install. On a fresh Mac, install the Brewfile first
(see Prerequisites), then run it.

## Prerequisites

The dotfiles are inert without the tools they set up. Install these first.

### macOS

Everything comes from [Homebrew](https://brew.sh). `Brewfile` is the manifest —
41 formulae, 49 casks, 6 taps, including `stow` itself.

```bash
brew bundle --file=~/dotfiles/Brewfile
```

At minimum, `bootstrap` itself needs:

```bash
brew install stow git zsh neovim
```

(all four are also in the Brewfile, so a `brew bundle` run covers this too).

### Linux

Not yet filled in — this needs a human at the actual Linux machine to work out
which packages it needs. The minimum is `stow git zsh neovim`; do **not**
derive the rest by translating the Brewfile — a macOS cask list doesn't map
onto Linux packages, and guessing here has caused problems before. Fill this
section in when the PC is set up.

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
`$HOME`. `git/.gitconfig` becomes `~/.gitconfig`. `zsh/.config/zsh/zshrc`
becomes `~/.config/zsh/zshrc`.

```bash
stow git          # link the git package into $HOME
stow -R git       # restow: remove and re-add, picks up new files
stow -D git       # unlink
stow -n -v git    # dry run, showing what would happen
```

Every package targets `$HOME` except `vscode`, which is macOS-only and targets
`~/Library/Application Support`. `bootstrap` handles that separately.

Before stowing, `bootstrap` walks every package's own directory tree and
pre-creates the matching directories under the target (`create_target_dirs`).
Without this, stow would link a missing target directory as a single symlink
back to the package directory instead of descending into it — which means
anything an app later writes under that path (Hammerspoon's `Spoons/`, herdr's
sockets and logs, Claude's `projects/`/`todos/`) would land inside the git
repo instead of in a real directory. The directory
set is derived from each package's contents at bootstrap time, not from a
hardcoded list, so it can't go stale when a package gains a new subdirectory.

**Editing a linked file edits tracked source directly.** There is no copy step
and no sync step — `~/.gitconfig` and `git/.gitconfig` are the same file on
disk. Changes show up in `git status` immediately and stay uncommitted until
you commit them.

## Which packages does a machine get?

`hosts/<hostname>.packages`, one package name per line. That file is the only
place machine-specific knowledge lives. This repo currently ships
`hosts/16-MacBook-Pro.packages`, `hosts/default-linux.packages`, and
`hosts/default-minimal.packages`. A machine with no file of its own falls back
to one of the two defaults depending on `uname`: Linux gets
`default-linux.packages`, anything else (including a Mac with no host file of
its own) gets `default-minimal.packages`.

## Machine-local files

Three files are generated per machine and must never be committed, so they are
not a stow package at all — `bootstrap` writes them straight to their real
paths and nothing links back into this repo:

| Path | What |
|------|------|
| `~/.zshrc` | shim that sources `~/.config/zsh/zshrc` |
| `~/.config/git/identity` | `[user]` name/email, included by `.gitconfig` |
| `~/.config/jj/conf.d/00-identity.toml` | the same identity for jj |

The `~/.zshrc` shim exists because tools append to that path — Herd rewrites
`HERD_PHP_*_INI_SCAN_DIR` on every PHP version change. Keeping it a real,
untracked file means those writes never reach tracked source. `bootstrap`
creates it only when it is absent, so appended lines survive a re-run.

## Neovim

One package, `nvim/.config/nvim`, stowed to `~/.config/nvim` — the path
Neovim reads by default, so no `$NVIM_APPNAME` is involved.

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
echo foo >> hosts/$(hostname -s).packages       # so bootstrap picks it up on every machine
```

The `hosts` line is the one that gets forgotten. Without it the package works
here but a fresh clone will not stow it.

Two habits worth keeping:

- **Add a line to `testing/expected-links.txt`.** Format is
  `<package> <path-under-$HOME> <path-in-repo>`. It costs one line and it is
  what proves a migration worked instead of eyeballing `ls -la`.
- **`stow -n -v foo` before `stow foo`** when unsure. It prints exactly what
  would happen without touching anything.

Links are per-file, not per-directory. Editing a linked file is live — it is
the same file on disk. But *adding* a new file to a package needs `stow -R foo`
(or `./bootstrap`) before it appears in `$HOME`.

## Fonts and wallpapers

`sketchybar-app-font` ships inside the `sketchybar` package, because that is the
only thing that uses it and sketchybar is macOS-only. macOS activates it through
the symlink — no copy step needed.

FiraCode and FiraMono come from Homebrew casks rather than being vendored here,
so they stay updated and do not put ~96MB of binaries in git. MonoLisa is a paid
per-seat font and is deliberately **not** in this repo; install it by hand.

`wallpapers/` is plain assets at the repo root, not a stow package — nothing
reads them from a fixed path.

## Commands

```bash
dot status        # repo status plus this host's package list
dot pull           # pull, then restow
dot push [msg]     # stage tracked changes, commit, push

./bootstrap                            # re-run linking; idempotent
./testing/stow-test.sh <package>...    # verify links in a throwaway HOME
stow -D <package>...                  # undo links for those packages
```
