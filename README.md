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
sockets and logs, Claude's `projects/`/`todos/`, `local/`'s generated files)
would land inside the git repo instead of in a real directory. The directory
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

`local/` is gitignored and holds the files that must never be committed: the
`~/.zshrc` shim and the generated git and jj identities. It is stowed like any
other package. Tools that append to `~/.zshrc` — Herd writes
`HERD_PHP_*_INI_SCAN_DIR` on every PHP version change — follow the symlink into
untracked space instead of into tracked source.

## Neovim

Two packages, both stowed, selected by `$NVIM_APPNAME`:

```bash
nvim                              # uses $NVIM_APPNAME, default nvim-custom
NVIM_APPNAME=nvim-lazyvim nvim    # the other one
```

Separate plugin state, separate `lazy-lock.json`. They share no Lua.

## The `bin` and `local` packages

`bin/.local/bin/dot` is the `dot` CLI (`dot status`, `dot pull`, `dot push`) —
stowed like any other package, so it lands on `$PATH` at `~/.local/bin/dot`
once `~/.local/bin` is on it. `local/` (see above) is the gitignored package
for machine-local, never-committed files.

## Commands

```bash
dot status        # repo status plus this host's package list
dot pull           # pull, then restow
dot push [msg]     # stage tracked changes, commit, push

./bootstrap                            # re-run linking; idempotent
./testing/stow-test.sh <package>...    # verify links in a throwaway HOME
stow -D <package>...                  # undo links for those packages
```
