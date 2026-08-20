# macOS-Only Flatten (2.0) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flatten the cross-platform dotfiles repo into a macOS-only repo: delete all Linux support, dissolve the `shared/` + `mac/` split into a flat root layout, and replace every build/copy step with a direct symlink.

**Architecture:** The build scripts existed only to concatenate a shared config with an OS-specific fragment. With one OS the fragment can be baked into the source file, so `~/.zshrc` and the Ghostty config become plain symlinks and the build scripts are deleted. `.gitconfig` follows the pattern `configure` already uses for jj: symlink the tracked file, and generate the machine-specific identity into a separate included file that is never committed.

**Tech Stack:** bash (system `/bin/bash`, **3.2**), zsh, Homebrew, launchd, git.

**Spec:** `docs/superpowers/specs/2026-07-31-macos-only-flatten-design.md` (landed by Task 1)

## Global Constraints

- **macOS only.** No `$OS`/`$DISTRO` detection, no apt/pacman/dnf, no COSMIC/hypr/keyd/Flatpak/Zen.
- **System bash is 3.2.** No `declare -A`, no associative arrays, no `${var^^}`. This is not theoretical — a `declare -A` in `prune-login-items.sh` failed silently and made the script a no-op.
- **Work directly on `main`**, one commit per task. Every commit must leave the repo in a working state: never land a path move without the path updates that go with it.
- **Preserve history:** move files with `git mv`, never delete-and-recreate.
- **`~/Code/dotfiles` may be hardcoded** in shell config (approved spec decision 4); the repo already does this in `install` and `README.md`.
- **`./configure` must stay idempotent** — it is run repeatedly, not just on a fresh Mac.
- Target version for the release: **2.0.0**.

## File Structure

Final root layout. Everything from `shared/` and `mac/` lands at the root; `linux/` is gone.

```
dotfiles/
├── setup configure install release              # entry scripts (mac/setup.sh folded into setup)
├── functions.sh                                 # was shared/functions.sh, mac-only
├── Brewfile                                     # shared/Brewfile + mac/Brewfile merged
├── CapsLockToControl.plist tcc-cleanup.sh prune-login-items.sh
├── zed-keymap.json
├── zsh/          zshrc + aliases.sh             # build.sh deleted
├── ghostty/      config + themes/               # mac lines baked in, build.sh deleted
├── git/          gitconfig + gitignore_global + hooks/
├── nvim/ lazygit/ zed/ jj/ claude/ fonts/ wallpapers/
├── hammerspoon/ vscode/ raycast/ sketchybar/ yabai/ keyboard_settings/
└── memory/ docs/ testing/ scripts/ .github/ .claude/
```

Deleted outright: `linux/`, `shared/zen/`, `cleanup.sh` (symlink into `linux/`), `buildghostty`, `buildzshrc`, `shared/ghostty/build.sh`, `shared/zsh/build.sh`, `mac/setup.sh`.

**Note:** the spec's target tree lists `phpstorm/`. That directory no longer exists — it was deleted after the spec was written. Do not recreate it.

---

### Task 1: Land the spec and its amendments

The spec currently exists only in a detached worktree, which will be removed. Bring it onto `main` so the plan's reasoning travels with the repo.

**Files:**
- Create: `docs/superpowers/specs/2026-07-31-macos-only-flatten-design.md`
- Create: `docs/superpowers/plans/2026-08-20-macos-only-flatten.md` (this file)

- [ ] **Step 1: Copy the spec out of the worktree**

```bash
cd ~/Code/dotfiles
cp .claude/worktrees/macos-only-dotfiles-dcf0a3/docs/superpowers/specs/2026-07-31-macos-only-flatten-design.md \
   docs/superpowers/specs/2026-07-31-macos-only-flatten-design.md
```

- [ ] **Step 2: Append the amendments to the spec**

The spec was approved 2026-07-31; two decisions were made after it. Append this section to the end of the copied spec file:

```markdown
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
```

- [ ] **Step 3: Verify the spec landed and is not empty**

```bash
wc -l docs/superpowers/specs/2026-07-31-macos-only-flatten-design.md
grep -c "Amendments (2026-08-20)" docs/superpowers/specs/2026-07-31-macos-only-flatten-design.md
```
Expected: >180 lines, and `1`.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/
git commit -m "docs: land macOS-only flatten spec and plan on main"
```

---

### Task 2: Delete Linux and Zen support

No file moves in this task — paths stay `shared/…` and `mac/…`. Only Linux-specific code is removed, so the repo keeps working on macOS throughout.

**Files:**
- Delete: `linux/` (tree), `shared/zen/` (tree), `cleanup.sh` (symlink)
- Modify: `setup`, `configure`, `install`, `testing/rollback.sh`, `shared/zsh/zshrc`
- **Not** `shared/functions.sh` — see the note below

**Interfaces:**
- Produces: no Linux code paths in `setup`/`configure`/`install`/`rollback.sh`.
- Consumes: nothing.

> **Do NOT touch `shared/functions.sh` in this task** (controller ruling R1).
> `shared/ghostty/build.sh` still consumes `append()` and `$OS`, and
> `shared/zsh/build.sh` still consumes `$OS`; both survive until Tasks 3 and 4
> delete them. Stripping functions.sh here would make Step 9's `./configure`
> rebuild the live `~/.zshrc` with no mac aliases and the live ghostty config
> with none of its mac lines — silently, because those failures happen inside a
> `bash` subprocess where `set -e` cannot see them. Task 6 does the rewrite.

- [ ] **Step 1: Assert the Linux surface exists (so the deletion is measurable)**

```bash
cd ~/Code/dotfiles
grep -rln '\$OS\|\$DISTRO' setup configure install
```
Expected: all four files listed. This is the "before" state.

- [ ] **Step 2: Delete the Linux and Zen trees**

```bash
git rm -r -q linux shared/zen
git rm -q cleanup.sh
```

- [ ] **Step 3: Strip Linux from `setup`**

Make these edits to `setup`:

1. Delete the whole `if [ "$OS" = "linux" ]; then … fi` block that installs core system packages (the `ensure_ca_trust` / `$PKG_UPDATE` / `apt_install` block).
2. In the Homebrew install block, delete the `if [ "$OS" = "linux" ]; then … fi` linuxbrew branch, leaving just the `NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL …)"` line.
3. Replace the `getent passwd` shell detection (Linux-only; `getent` does not exist on macOS) with a macOS-safe form:

```bash
# Set zsh as default shell
ZSH_PATH="$(command -v zsh)"
if [ -n "$ZSH_PATH" ]; then
    # chsh requires the target shell to be listed in /etc/shells
    if ! grep -qxF "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
    fi
    CURRENT_SHELL="$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')"
    if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
        echo "Setting zsh as default shell..."
        chsh -s "$ZSH_PATH"
    fi
fi
```

4. Replace the OS-specific setup branch with an unconditional source (folded inline in Task 7):

```bash
echo "Running Mac setup..."
source "$DOTFILES_DIR/mac/setup.sh"
```

5. Replace the fonts block with the macOS branch only:

```bash
# Fonts — macOS fontd only activates fonts placed *directly* in ~/Library/Fonts,
# not in subfolders, so flatten the .ttf/.otf files out of their per-family dirs.
echo "Installing fonts..."
mkdir -p ~/Library/Fonts
find "$DOTFILES_DIR/shared/fonts" -type f \( -iname '*.ttf' -o -iname '*.otf' \) \
    -exec cp {} ~/Library/Fonts/ \;
```

6. Delete the trailing `if [ "$OS" = "linux" ]; then … reboot … fi` block.

- [ ] **Step 4: Strip Linux and Zen from `configure`**

1. `lazygit` — drop the branch, keep the mac path:

```bash
link "$DOTFILES_DIR/shared/lazygit" "$HOME/Library/Application Support/lazygit"
```

2. Zed keymap — drop the branch:

```bash
link "$DOTFILES_DIR/mac/zed-keymap.json" ~/.config/zed/keymap.json
```

3. Hammerspoon/VS Code — remove the `if [ "$OS" = "mac" ]` wrapper, keep the four lines inside it unconditional.
4. **Delete the entire Zen Browser block** — the `MKCERT_ROOT_CA` lines, the `for ZEN_ROOT in …` loop, and their comment header (lines 79–106).

- [ ] **Step 5: Strip Linux from `install`**

Replace the OS branch with the macOS path only:

```bash
# Install Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install 2>/dev/null || true
    until xcode-select -p &>/dev/null; do sleep 5; done
fi
```

- [ ] **Step 6: Remove the Linux `Homebrew (Linux)` block from `shared/zsh/zshrc`**

Delete these five lines (the block at lines 20–24):

```bash
# Homebrew (Linux)
if [ -d /home/linuxbrew/.linuxbrew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
fi
```

- [ ] **Step 7: Strip Linux from `testing/rollback.sh`**

Delete the "Remove Flatpak Zed symlinks" block (3 `rm -f` lines) and the "Remove arch-specific symlinks" block (7 `rm -f` lines). Change the closing note to:

```bash
echo "Note: Installed packages (brew) were left in place."
```

- [ ] **Step 8: Verify no Linux surface remains**

```bash
cd ~/Code/dotfiles
bash -n setup && bash -n configure && bash -n install && bash -n testing/rollback.sh && echo "syntax OK"
grep -rn '\$OS\|\$DISTRO\|apt_install\|pacman\|dnf\|linuxbrew\|getent\|Flatpak\|zen' setup configure install shared/zsh/zshrc testing/rollback.sh
```
Expected: `syntax OK`, and the grep returns **nothing**.

- [ ] **Step 9: Verify configure still runs clean**

```bash
./configure && echo "configure OK"
```
Expected: `configure OK`, no errors.

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "Drop Linux and Zen support

Deletes linux/ and shared/zen/ wholesale, strips every \$OS/\$DISTRO branch
from setup/configure/install, and removes the Flatpak and arch blocks from
testing/rollback.sh. Paths are untouched; the flatten follows.

functions.sh keeps its Linux helpers for now: the ghostty and zsh build scripts
still consume $OS and append(), and they are not deleted until the next two
commits.

getent doesn't exist on macOS, so default-shell detection moves to
dscl . -read."
```

---

### Task 3: Flatten zsh and symlink `~/.zshrc`

**Files:**
- Move: `shared/zsh/` → `zsh/`
- Modify: `zsh/zshrc`, `zsh/aliases.sh`
- Delete: `buildzshrc`, `zsh/build.sh`, `mac/zsh/`
- Modify: `configure`

**Interfaces:**
- Consumes: `link()` from `functions.sh` (Task 2).
- Produces: `~/.zshrc` as a symlink to `zsh/zshrc`, which sources `zsh/aliases.sh` by absolute path.

- [ ] **Step 1: Assert the current state is a built file, not a symlink**

```bash
test -L ~/.zshrc && echo "already a symlink" || echo "regular file (built) — expected before state"
```
Expected: `regular file (built) — expected before state`.

- [ ] **Step 2: Move the directory, preserving history**

```bash
cd ~/Code/dotfiles
git mv shared/zsh zsh
git rm -q zsh/build.sh buildzshrc
```

- [ ] **Step 3: Merge the mac aliases into `zsh/aliases.sh`**

Append the entire contents of `mac/zsh/aliases.sh` to the end of `zsh/aliases.sh`, then remove the old file:

```bash
echo "" >> zsh/aliases.sh
cat mac/zsh/aliases.sh >> zsh/aliases.sh
git rm -r -q mac/zsh
```

- [ ] **Step 4: Fix the two now-wrong paths inside `zsh/aliases.sh`**

`sourcez` referenced the deleted build script, and `brewup` referenced the pre-flatten `mac/` paths. Make these three replacements:

```bash
cd ~/Code/dotfiles
# sourcez: no build step to run any more
sed -i '' 's|alias sourcez="~/Code/dotfiles/buildzshrc && source ~/.zshrc"|alias sourcez="source ~/.zshrc"|' zsh/aliases.sh
# brewup: flat paths
sed -i '' 's|~/Code/dotfiles/mac/tcc-cleanup.sh|~/Code/dotfiles/tcc-cleanup.sh|' zsh/aliases.sh
sed -i '' 's|~/Code/dotfiles/mac/prune-login-items.sh|~/Code/dotfiles/prune-login-items.sh|' zsh/aliases.sh
```

- [ ] **Step 5: Make `zsh/zshrc` source the aliases**

Append to the end of `zsh/zshrc`:

```bash
# Aliases and functions. Sourced rather than concatenated at build time — the
# whole file is symlinked to ~/.zshrc now, so edits are live.
source "$HOME/Code/dotfiles/zsh/aliases.sh"
```

- [ ] **Step 6: Replace the build call in `configure` with a symlink**

Change:

```bash
# Build .zshrc
bash "$DOTFILES_DIR/buildzshrc"
```

to:

```bash
# zshrc — symlinked, so edits are live; it sources zsh/aliases.sh itself
link "$DOTFILES_DIR/zsh/zshrc" ~/.zshrc
```

- [ ] **Step 7: Run configure and verify `~/.zshrc` is now a symlink**

```bash
cd ~/Code/dotfiles
./configure >/dev/null && ls -la ~/.zshrc
```
Expected: `~/.zshrc -> /Users/karlm/Code/dotfiles/zsh/zshrc`.

- [ ] **Step 8: Verify the shell actually loads, with aliases present**

```bash
zsh -ic 'exit' && echo "zshrc loads clean"
zsh -ic 'functions brewup' | grep -c 'prune-login-items' 
zsh -ic 'alias sourcez'
```
Expected: `zshrc loads clean`; `1`; and `sourcez='source ~/.zshrc'`.

- [ ] **Step 9: Verify the flat paths brewup calls actually resolve**

The files are still at `mac/` until Task 7, so confirm the *intended* targets are what Task 7 will produce, and that no `mac/` path survives in the aliases:

```bash
grep -n 'mac/' zsh/aliases.sh || echo "no mac/ paths left in aliases"
```
Expected: `no mac/ paths left in aliases`.

> **Known temporary breakage:** `brewup` now points at `~/Code/dotfiles/tcc-cleanup.sh` and `~/Code/dotfiles/prune-login-items.sh`, which do not exist until Task 7 moves them. Do not run `brewup` between this task and Task 7.

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "zsh: symlink .zshrc instead of building it

shared/zsh + mac/zsh merge into one zsh/ directory. The build step only
existed to concatenate the shared zshrc with an OS-specific aliases file;
with one OS, zshrc sources zsh/aliases.sh directly and ~/.zshrc becomes a
symlink, so edits are live.

sourcez no longer runs a build. brewup's tcc-cleanup and prune-login-items
paths are flattened ahead of the file moves in a later commit."
```

---

### Task 4: Flatten Ghostty and symlink its config

**Files:**
- Move: `shared/ghostty/` → `ghostty/`
- Modify: `ghostty/config` (bake in the mac lines)
- Delete: `buildghostty`, `ghostty/build.sh`
- Modify: `configure`

**Interfaces:**
- Consumes: `link()` from `functions.sh`.
- Produces: `~/.config/ghostty/config` and `~/Library/Application Support/com.mitchellh.ghostty/config` both symlinks to `ghostty/config`; `themes` symlinked in both locations.

- [ ] **Step 1: Assert current state is a copied file**

```bash
test -L ~/.config/ghostty/config && echo "symlink" || echo "regular file (built) — expected before state"
```
Expected: `regular file (built) — expected before state`.

- [ ] **Step 2: Move the directory and delete the build scripts**

```bash
cd ~/Code/dotfiles
git mv shared/ghostty ghostty
git rm -q ghostty/build.sh buildghostty
```

- [ ] **Step 3: Bake the eight mac lines into `ghostty/config`**

Append to the end of `ghostty/config`. These are the exact `append` lines the deleted `build.sh` added on macOS:

```
macos-titlebar-proxy-icon = hidden
font-size = 18
window-padding-y = 8,0
window-padding-x = 8,8
macos-option-as-alt = true
keybind = cmd+shift+h=goto_split:left
keybind = cmd+shift+l=goto_split:right

# Ghostty tabs on macOS are native NSWindow tabs — one real AXStandardWindow
# per tab — so yabai tiles each tab as its own window and the desk splits in
# half behind an invisible tab. No config makes them non-native; unbind
# instead. Use splits (cmd+d) or a real window (cmd+n).
keybind = cmd+t=unbind
```

Also update the existing `ctrl+shift+x` comment, which explains itself in terms of GTK on Linux. Replace that comment with:

```
# ctrl+shift+w was hijacked by GTK when this repo still targeted Linux; the
# binding stayed because muscle memory did. Kept as-is deliberately.
keybind = ctrl+shift+x=close_surface
```

- [ ] **Step 4: Replace the build call in `configure` with four symlinks**

Change:

```bash
# Build Ghostty config
bash "$DOTFILES_DIR/buildghostty"
```

to:

```bash
# Ghostty — symlinked in both locations macOS reads from, so edits are live
link "$DOTFILES_DIR/ghostty/config" ~/.config/ghostty/config
link "$DOTFILES_DIR/ghostty/themes" ~/.config/ghostty/themes
link "$DOTFILES_DIR/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
link "$DOTFILES_DIR/ghostty/themes" "$HOME/Library/Application Support/com.mitchellh.ghostty/themes"
```

- [ ] **Step 5: Update `testing/rollback.sh` for the new ghostty layout**

`rollback.sh` removes `~/.config/ghostty` as a single directory symlink. That is
now wrong twice over: the directory is no longer a symlink (its `config` and
`themes` children are), and the Application Support copies were never removed
at all. Replace the `rm -f ~/.config/ghostty` line with:

```bash
rm -f ~/.config/ghostty/config
rm -f ~/.config/ghostty/themes
rm -f "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
rm -f "$HOME/Library/Application Support/com.mitchellh.ghostty/themes"
```

- [ ] **Step 6: Run configure and verify all four symlinks**

```bash
cd ~/Code/dotfiles
./configure >/dev/null
ls -la ~/.config/ghostty/config ~/.config/ghostty/themes \
      "$HOME/Library/Application Support/com.mitchellh.ghostty/config" \
      "$HOME/Library/Application Support/com.mitchellh.ghostty/themes"
```
Expected: all four are symlinks into `~/Code/dotfiles/ghostty/`.

- [ ] **Step 7: Verify the baked config is complete**

Every line the old build script appended must now be in the tracked file:

```bash
cd ~/Code/dotfiles
for k in "macos-titlebar-proxy-icon = hidden" "font-size = 18" "window-padding-y = 8,0" \
         "window-padding-x = 8,8" "macos-option-as-alt = true" \
         "keybind = cmd+shift+h=goto_split:left" "keybind = cmd+shift+l=goto_split:right" \
         "keybind = cmd+t=unbind"; do
  grep -qF "$k" ghostty/config && echo "  ok: $k" || echo "  MISSING: $k"
done
```
Expected: eight `ok:` lines, no `MISSING`.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "ghostty: symlink the config instead of building it

The build script existed to append OS-specific lines to a shared base. With
one OS those eight macOS lines are baked into ghostty/config, which is now
symlinked to both locations macOS reads from — so edits are live.

rollback.sh removed ~/.config/ghostty as one directory symlink, which no
longer matches (the children are the symlinks now) and never covered the
Application Support pair; it removes all four explicitly instead.

Also rewrites the ctrl+shift+x comment, which explained itself in terms of a
GTK bug on a platform this repo no longer targets."
```

---

### Task 5: Symlink `.gitconfig` with a generated identity include

`configure` sets `user.name`/`user.email` with `git config --global`, which writes to `~/.gitconfig` — so symlinking it naively would commit the machine's identity into the repo. `configure` already solves exactly this for jj by generating `conf.d/00-identity.toml`; apply the same shape to git via `[include]`.

**Files:**
- Modify: `shared/git/gitconfig`, `configure`, `testing/rollback.sh`

**Interfaces:**
- Consumes: `link()` from `functions.sh`.
- Produces: `~/.gitconfig` as a symlink; `~/.config/git/identity` as a generated, untracked file holding `user.name` and `user.email`.

- [ ] **Step 1: Record the current identity so the change is verifiable**

```bash
git config --global user.name; git config --global user.email
ls -la ~/.gitconfig
```
Expected: the name/email print, and `~/.gitconfig` is a regular file. Note the values — the same ones must survive.

- [ ] **Step 2: Add the include to `shared/git/gitconfig`**

Append to the file. `path` is relative-expanded by git from `~`, and a **missing** include file is silently ignored by git, so this is safe before `configure` has generated it:

```ini
[include]
	path = ~/.config/git/identity
```

- [ ] **Step 3: Replace the copy with a symlink in `configure`**

Change the git block to:

```bash
# Git config — symlinked, so edits are live. user.name/user.email are
# machine-specific and `git config --global` writes to ~/.gitconfig, which is
# now this repo's file — so keep the identity in a separate generated file that
# gitconfig [include]s, exactly as the jj block below does with conf.d/.
GIT_NAME="$(git config --global user.name 2>/dev/null || true)"
GIT_EMAIL="$(git config --global user.email 2>/dev/null || true)"
link "$DOTFILES_DIR/shared/git/gitconfig" ~/.gitconfig
link "$DOTFILES_DIR/shared/git/gitignore_global" ~/.gitignore_global
mkdir -p ~/.config/git
if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
    cat > ~/.config/git/identity <<EOF
# generated by ./configure — do not edit, and do not commit
[user]
	name = $GIT_NAME
	email = $GIT_EMAIL
[core]
	excludesfile = $HOME/.gitignore_global
EOF
else
    echo "Skipping git identity — no user.name/user.email found; set them with 'git config --file ~/.config/git/identity user.name \"…\"'"
fi
```

Note `core.excludesfile` moves into the generated file too, for the same reason: `git config --global core.excludesfile` would otherwise write into the repo.

- [ ] **Step 4: Reset the identity capture in `setup`**

`setup` also runs `git config --global user.name "$GIT_NAME"` after prompting. Change that block so it writes to the identity file instead of `~/.gitconfig`:

```bash
# Git identity — written to the generated include, not ~/.gitconfig (which is
# a symlink into this repo). ./configure regenerates this file too.
mkdir -p ~/.config/git
git config --file ~/.config/git/identity user.name "$GIT_NAME"
git config --file ~/.config/git/identity user.email "$GIT_EMAIL"
```

and delete the now-redundant `rm -f ~/.gitconfig` / `cp …/gitconfig ~/.gitconfig` / `git config --global core.excludesfile` lines from `setup` — `configure` (run at the end of `setup`) does all of it.

- [ ] **Step 5: Run configure and verify the symlink plus identity**

```bash
cd ~/Code/dotfiles
./configure >/dev/null
ls -la ~/.gitconfig
cat ~/.config/git/identity
```
Expected: `~/.gitconfig -> /Users/karlm/Code/dotfiles/shared/git/gitconfig`, and the identity file contains the same name/email from Step 1.

- [ ] **Step 6: Verify git still resolves the identity and excludes file**

```bash
git config --get user.name
git config --get user.email
git config --get core.excludesfile
```
Expected: the original name and email, and `/Users/karlm/.gitignore_global`.

- [ ] **Step 7: Verify the repo was not polluted**

This is the whole point of the include — the symlinked file must be unchanged:

```bash
cd ~/Code/dotfiles
git status --short shared/git/gitconfig
grep -c "user" shared/git/gitconfig
```
Expected: `git status` shows the file only as the staged `[include]` edit (no identity lines), and the `grep -c` counts **0** occurrences of a `user` section beyond your intended text. Confirm by eye that no name or email appears:

```bash
grep -n "name\|email" shared/git/gitconfig || echo "no identity in the tracked file — correct"
```

- [ ] **Step 8: Add the identity reset to `testing/rollback.sh`**

Change the `.gitconfig` reset block to also clear the generated file:

```bash
# Reset .gitconfig and the generated identity include
echo "Resetting .gitconfig..."
rm -f ~/.gitconfig
rm -f ~/.config/git/identity
```

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "git: symlink .gitconfig, generate the identity separately

.gitconfig was copied rather than symlinked because configure runs
'git config --global user.name/email', which would have written the machine's
identity into the repo.

Symlink it and [include] a generated ~/.config/git/identity holding
user.name, user.email and core.excludesfile — the same shape configure
already uses for jj's conf.d/00-identity.toml. Git ignores a missing include,
so this is safe before configure has run."
```

---

### Task 6: Move the remaining `shared/` directories to the root

**Files:**
- Rewrite: `shared/functions.sh` (Linux helpers out — deferred from Task 2 by ruling R1)
- Move: `shared/{functions.sh,Brewfile,nvim,lazygit,zed,git,jj,claude,fonts,wallpapers}` → root
- Modify: `setup`, `configure`, `.gitignore`

**Interfaces:**
- Consumes: nothing new.
- Produces: no `shared/` directory; `functions.sh` at the repo root, sourced as `"$DOTFILES_DIR/functions.sh"`.

- [ ] **Step 1: Rewrite `functions.sh` to the three mac-only helpers**

Deferred here from Task 2 by controller ruling R1: the ghostty and zsh build
scripts consumed `append()` and `$OS` until Tasks 3 and 4 deleted them, so
stripping this file earlier would have silently rebuilt the live `~/.zshrc` and
ghostty config from the wrong branches. Both build scripts are gone now, so
nothing consumes either symbol.

Do this before the move below, so the diff reads as an edit rather than a
rewrite-plus-rename.

Replace the whole file with:

```bash
#!/bin/bash

# Remove existing and symlink
link() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "link() error: missing argument" >&2
        return 1
    fi
    mkdir -p "$(dirname "$2")"
    rm -rf "$2"
    ln -snf "$1" "$2"
}

# Install only missing brew formulae
brew_install() {
    local missing=()
    for pkg in "$@"; do
        if ! brew list "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Installing: ${missing[*]}"
        brew install "${missing[@]}"
    fi
}

# Install only missing brew casks
brew_install_cask() {
    local missing=()
    for pkg in "$@"; do
        if ! brew list --cask "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Installing casks: ${missing[*]}"
        brew install --cask "${missing[@]}"
    fi
}
```

- [ ] **Step 2: Move everything left in `shared/`**

```bash
cd ~/Code/dotfiles
git mv shared/functions.sh functions.sh
git mv shared/Brewfile Brewfile.shared
for d in nvim lazygit zed git jj claude fonts wallpapers; do git mv "shared/$d" "$d"; done
rmdir shared 2>/dev/null || true
```

`Brewfile.shared` is a deliberate temporary name — Task 7 merges it with `mac/Brewfile` into `Brewfile`.

- [ ] **Step 3: Repoint every `shared/` path in `setup` and `configure`**

```bash
cd ~/Code/dotfiles
sed -i '' 's|\$DOTFILES_DIR/shared/|$DOTFILES_DIR/|g' setup configure
sed -i '' 's|\$DOTFILES_DIR/Brewfile"|$DOTFILES_DIR/Brewfile.shared"|' setup
```

The second `sed` keeps `setup`'s shared-Brewfile bundle call pointing at the temporary name until Task 7 merges it.

- [ ] **Step 4: Update `.gitignore` for the new paths**

Replace the first three lines:

```
nvim/lazy-lock.json
zed/prompts/
lazygit/state.yml
node_modules/
.superpowers/
```

- [ ] **Step 5: Verify no `shared/` references remain**

```bash
cd ~/Code/dotfiles
bash -n setup && bash -n configure && bash -n functions.sh && echo "syntax OK"
grep -rn 'shared/' setup configure install functions.sh testing/rollback.sh .gitignore || echo "no shared/ references"
grep -n '\$OS\|\$DISTRO\|apt_install\|pacman_install\|dnf_install\|ensure_ca_trust\|append()' functions.sh || echo "functions.sh is mac-only"
test -d shared && echo "shared/ STILL EXISTS" || echo "shared/ gone"
```
Expected: `syntax OK`, `no shared/ references`, `shared/ gone`.

- [ ] **Step 6: Run configure and verify the symlinks still resolve**

Dangling symlinks are the main risk of a move, so check the targets exist:

```bash
cd ~/Code/dotfiles
./configure >/dev/null && echo "configure OK"
for l in ~/.config/nvim ~/.gitconfig ~/.zshrc ~/.config/jj/config.toml \
         ~/.config/zed/settings.json ~/.claude/skills/general \
         "$HOME/Library/Application Support/lazygit"; do
  if [ -e "$l" ]; then echo "  ok: $l -> $(readlink "$l")"; else echo "  DANGLING: $l"; fi
done
```
Expected: `configure OK` and seven `ok:` lines with no `DANGLING`.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "Move shared/ contents to the repo root, strip functions.sh

git mv throughout so history follows the files. functions.sh, Brewfile and
the eight config directories move up one level; .gitignore and every
\$DOTFILES_DIR path in setup/configure follow.

functions.sh loses the Linux helpers here rather than in the first commit:
the ghostty and zsh build scripts consumed \$OS and append() until the two
commits before this one deleted them.

The shared Brewfile lands as Brewfile.shared temporarily; the next commit
merges it with the mac one."
```

---

### Task 7: Move `mac/` to the root, merge the Brewfiles, fold `mac/setup.sh` into `setup`

**Files:**
- Move: `mac/{CapsLockToControl.plist,tcc-cleanup.sh,prune-login-items.sh,zed-keymap.json,hammerspoon,vscode,raycast,sketchybar,yabai,keyboard_settings}` → root
- Create: `Brewfile` (merge of `Brewfile.shared` + `mac/Brewfile`)
- Delete: `mac/setup.sh`, `Brewfile.shared`, `mac/Brewfile`
- Modify: `setup`, `configure`, `sketchybar/helpers/tests/run` (comment only)

**Interfaces:**
- Consumes: `link()`, `brew_install*()` from `functions.sh`.
- Produces: no `mac/` directory; a single root `Brewfile`; `setup` with the former `mac/setup.sh` body inline.

- [ ] **Step 1: Move everything out of `mac/` except the two files handled separately**

```bash
cd ~/Code/dotfiles
git mv mac/CapsLockToControl.plist CapsLockToControl.plist
git mv mac/tcc-cleanup.sh tcc-cleanup.sh
git mv mac/prune-login-items.sh prune-login-items.sh
git mv mac/zed-keymap.json zed-keymap.json
for d in hammerspoon vscode raycast sketchybar yabai keyboard_settings; do git mv "mac/$d" "$d"; done
```

- [ ] **Step 2: Merge the two Brewfiles into one**

Concatenate with the taps hoisted to the top, since `brew bundle` wants `tap` lines before the entries that use them:

```bash
cd ~/Code/dotfiles
{
  grep '^tap ' Brewfile.shared mac/Brewfile | sed 's/^[^:]*://' | sort -u
  echo
  grep -v '^tap ' Brewfile.shared | sed '/^$/d'
  echo
  grep -v '^tap ' mac/Brewfile | sed '/^$/d'
} > Brewfile
git add Brewfile
git rm -q Brewfile.shared mac/Brewfile
```

- [ ] **Step 3: Verify the merged Brewfile is complete and parseable**

Nothing may be lost in the merge, and `brew bundle` must accept the Ruby DSL:

```bash
cd ~/Code/dotfiles
echo "taps:   $(grep -c '^tap '  Brewfile)"
echo "brews:  $(grep -c '^brew ' Brewfile)"
echo "casks:  $(grep -c '^cask ' Brewfile)"
brew bundle list --file=Brewfile >/dev/null && echo "brew bundle parses OK"
```
Expected: **5 taps, 39 brews, 49 casks** — that is 2+3 taps, 31+8 brews, 0+49 casks, verified against the pre-merge files. Any other number means the merge dropped or duplicated entries. And `brew bundle parses OK`.

- [ ] **Step 4: Fold `mac/setup.sh` inline into `setup`**

Replace the `echo "Running Mac setup..."` / `source "$DOTFILES_DIR/mac/setup.sh"`
pair in `setup` with the block below. This is the whole of `mac/setup.sh` with
every `mac/` path flattened and the Brewfile repointed at the merged root file.
Every comment is preserved deliberately — each one records a bug that took real
debugging to find.

```bash
# Mac packages
echo "Installing Mac packages..."
# Homebrew refuses to load formulae from third-party taps until they're trusted.
# Tap + trust every non-official tap the Brewfile uses (including osx-cross/{arm,avr}
# pulled in transitively by qmk) before bundling, or the install aborts on a fresh Mac.
for t in qmk/qmk osx-cross/arm osx-cross/avr FelixKratz/formulae koekeishiya/formulae; do
  brew tap "$t"
  brew trust "$t"
done
brew bundle --file="$DOTFILES_DIR/Brewfile"

# Rust via rustup. The rustup formula is keg-only because it collides with the
# `rust` formula, which links its own cargo/rustc into /opt/homebrew/bin — and
# those can't see rustup's toolchain, so anything needing a non-native target
# (e.g. Zed compiling a dev extension for wasm32-wasip2) fails with a confusing
# "target may not be installed". Unlink rust, force-link rustup, then make sure
# a toolchain exists; Zed adds targets itself once rustup is in charge.
brew unlink rust 2>/dev/null || true
brew link --force --overwrite rustup
rustup toolchain list 2>/dev/null | grep -q '^stable-' || rustup default stable

# Caps Lock → Control (at boot via LaunchDaemon, Hammerspoon adds tap-for-Escape)
sudo cp "$DOTFILES_DIR/CapsLockToControl.plist" /Library/LaunchDaemons/com.dotfiles.CapsLockToControl.plist
sudo chown root:wheel /Library/LaunchDaemons/com.dotfiles.CapsLockToControl.plist
sudo chmod 644 /Library/LaunchDaemons/com.dotfiles.CapsLockToControl.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.dotfiles.CapsLockToControl.plist 2>/dev/null || true

# Hammerspoon
link "$DOTFILES_DIR/hammerspoon" ~/.hammerspoon

# VS Code
link "$DOTFILES_DIR/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
link "$DOTFILES_DIR/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"

# Sketchybar
link "$DOTFILES_DIR/sketchybar" ~/.config/sketchybar

# menubar-toggle keepalive: launchd owns it so `sketchybar --reload` can't orphan
# it (sketchybarrc no longer launches it). Symlink the agent and (re)bootstrap.
link "$DOTFILES_DIR/sketchybar/com.dotfiles.menubar-toggle.plist" ~/Library/LaunchAgents/com.dotfiles.menubar-toggle.plist
pkill -x menubar-toggle 2>/dev/null || true
launchctl bootout "gui/$(id -u)/com.dotfiles.menubar-toggle" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/com.dotfiles.menubar-toggle.plist 2>/dev/null || true

# yabai + skhd (tiling window manager)
link "$DOTFILES_DIR/yabai/yabairc" ~/.yabairc
link "$DOTFILES_DIR/yabai/skhdrc" ~/.skhdrc

# yabai sudoers: allow --load-sa / --uninstall-sa without password.
# yabai's default sudoers entry pins a sha256 of the binary, which breaks on
# every brew upgrade (SA stops loading, --sub-layer / space ops fail). Drop
# the hash so brewup can reload the scripting addition non-interactively.
echo 'karlm ALL = (root) NOPASSWD: /opt/homebrew/bin/yabai --load-sa, /opt/homebrew/bin/yabai --uninstall-sa' \
  | sudo tee /etc/sudoers.d/yabai >/dev/null
sudo chmod 440 /etc/sudoers.d/yabai
sudo visudo -c -f /etc/sudoers.d/yabai

# Start the window-manager stack. --restart-service reloads the freshly-symlinked
# config when the launchd agent is already installed; on a fresh Mac it isn't yet,
# so fall back to --start-service which installs and boots it.
yabai --restart-service 2>/dev/null || yabai --start-service
skhd --restart-service 2>/dev/null || skhd --start-service
brew services restart sketchybar

# Prune Adobe/Google background agents and any launchd plists left orphaned by
# a `brew uninstall` that skipped `brew services stop`. Runs with `bash` (not
# sourced) so its exit status can't trip setup's `set -e`, and as the invoking
# user because it needs the gui/$UID domain — it calls sudo itself where needed.
bash "$DOTFILES_DIR/prune-login-items.sh" || true
```

Then remove the file and the now-empty directory:

```bash
git rm -q mac/setup.sh
rmdir mac 2>/dev/null || true
```

- [ ] **Step 5: Repoint the remaining `mac/` paths in `configure`**

```bash
cd ~/Code/dotfiles
sed -i '' 's|\$DOTFILES_DIR/mac/|$DOTFILES_DIR/|g' configure setup
```

- [ ] **Step 6: Update the stale path in the sketchybar test runner comment**

```bash
sed -i '' 's|mac/sketchybar/helpers/menubar-toggle|sketchybar/helpers/menubar-toggle|' sketchybar/helpers/tests/run
```

- [ ] **Step 7: Verify no `mac/` references remain anywhere**

```bash
cd ~/Code/dotfiles
bash -n setup && bash -n configure && bash -n prune-login-items.sh && bash -n tcc-cleanup.sh && echo "syntax OK"
grep -rn 'DOTFILES_DIR/mac/\|dotfiles/mac/\|shared/' setup configure install functions.sh zsh/aliases.sh testing/rollback.sh || echo "no mac/ or shared/ references"
test -d mac && echo "mac/ STILL EXISTS" || echo "mac/ gone"
```
Expected: `syntax OK`, `no mac/ or shared/ references`, `mac/ gone`.

- [ ] **Step 8: Verify the paths `brewup` calls now exist**

These were pointed at flat paths in Task 3 and were dangling until now:

```bash
cd ~/Code/dotfiles
test -f tcc-cleanup.sh && echo "  ok: tcc-cleanup.sh" || echo "  MISSING tcc-cleanup.sh"
test -f prune-login-items.sh && echo "  ok: prune-login-items.sh" || echo "  MISSING prune-login-items.sh"
bash prune-login-items.sh --dry-run >/dev/null && echo "  prune script runs from its new path"
```
Expected: two `ok:` lines and the dry run succeeding.

- [ ] **Step 9: Run configure and re-verify every symlink**

```bash
cd ~/Code/dotfiles
./configure >/dev/null && echo "configure OK"
for l in ~/.hammerspoon ~/.config/sketchybar ~/.yabairc ~/.skhdrc ~/.config/zed/keymap.json \
         ~/.config/ghostty/config ~/.zshrc ~/.gitconfig; do
  if [ -e "$l" ]; then echo "  ok: $l -> $(readlink "$l")"; else echo "  DANGLING: $l"; fi
done
```
Expected: `configure OK`, eight `ok:` lines, no `DANGLING`.

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "Move mac/ contents to the repo root and merge the Brewfiles

Completes the flatten: shared/ and mac/ are both gone. The two Brewfiles
merge into one with taps hoisted to the top, and mac/setup.sh folds inline
into setup now that there is no second OS to branch on.

Also repoints the sketchybar test runner's header comment and restores the
tcc-cleanup / prune-login-items paths brewup started pointing at earlier."
```

---

### Task 8: Rewrite the docs

**Files:**
- Modify: `README.md`, `CLAUDE.md`
- Review: `memory/*.md`

- [ ] **Step 1: Rewrite `CLAUDE.md`**

Required changes:
- Intro: "Cross-platform dotfiles for macOS and Linux (Debian/Ubuntu + Arch + Fedora)" → macOS only.
- Architecture: `functions.sh` now provides only `link()`, `brew_install()`, `brew_install_cask()`. Delete the `$OS` / `$DISTRO` / `$PKG` bullets.
- Script chain: collapse to `setup → functions.sh → configure`. No `buildzshrc`, no `mac/setup.sh`, no `linux/`.
- Directory structure: replace with the flat tree from this plan's File Structure section.
- **Delivery table:** this is the section most likely to mislead a future reader. `.zshrc`, Ghostty config and `.gitconfig` all move from "Built"/"Copied" to "Symlinked". What remains genuinely non-symlinked is only: COSMIC (gone), Zen (gone), fonts (still copied — macOS `fontd` only activates fonts placed directly in `~/Library/Fonts`), and `~/.config/git/identity` + `~/.config/jj/conf.d/00-identity.toml` (generated, never committed). Rewrite the table to exactly that.
- Conventions: drop "Mac is the source of truth for shared configs" (there is only one) and the `source` not `bash` note about sharing a sudo session with Linux child scripts.
- Key aliases: drop the Linux `a = ddev artisan` row; keep `a = php artisan`.
- Add `prune-login-items.sh` to the documented scripts.

- [ ] **Step 2: Rewrite `README.md`**

- New tagline: macOS only.
- New structure tree (flat).
- Delete all Platform Details / Linux / COSMIC sections.
- "What It Does": no OS detection.
- Useful Commands: `~/Code/dotfiles/buildzshrc && source ~/.zshrc` → `source ~/.zshrc`.

- [ ] **Step 3: Check `memory/` for entries the flatten makes stale**

```bash
cd ~/Code/dotfiles
grep -rln 'shared/\|linux/\|mac/\|buildzshrc\|buildghostty\|DISTRO\|COSMIC\|Flatpak' memory/
```
For each hit, update the path or note it as historical. Do not delete memories that were true at the time — correct the paths.

- [ ] **Step 4: Verify no stale references survive in docs**

```bash
cd ~/Code/dotfiles
grep -rn 'buildzshrc\|buildghostty\|shared/\|linux/\|DISTRO\|COSMIC\|Flatpak\|ddev artisan' README.md CLAUDE.md || echo "docs clean"
```
Expected: `docs clean`.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "docs: rewrite README and CLAUDE.md for macOS-only

Notably the delivery table: .zshrc, ghostty and .gitconfig all move to
Symlinked. The only non-symlinked configs left are fonts (macOS fontd won't
activate them from a subfolder or, in practice, reliably via symlink) and the
two generated identity files."
```

---

### Task 9: Final verification and the 2.0.0 release

- [ ] **Step 1: Full static check**

```bash
cd ~/Code/dotfiles
for f in setup configure install release functions.sh tcc-cleanup.sh prune-login-items.sh testing/rollback.sh; do
  bash -n "$f" && echo "  ok: $f" || echo "  FAIL: $f"
done
zsh -n zsh/aliases.sh && echo "  ok: zsh/aliases.sh"
```
Expected: all `ok:`.

- [ ] **Step 2: Assert the flatten is complete**

```bash
cd ~/Code/dotfiles
test -d shared && echo "FAIL shared/ exists" || echo "  ok: no shared/"
test -d linux  && echo "FAIL linux/ exists"  || echo "  ok: no linux/"
test -d mac    && echo "FAIL mac/ exists"    || echo "  ok: no mac/"
for f in buildzshrc buildghostty cleanup.sh; do
  test -e "$f" && echo "FAIL $f exists" || echo "  ok: no $f"
done
grep -rn '\$OS\|\$DISTRO' setup configure install functions.sh || echo "  ok: no OS branching"
```
Expected: all `ok:`.

- [ ] **Step 3: Confirm every delivered config is a symlink except the known exceptions**

```bash
for l in ~/.zshrc ~/.gitconfig ~/.gitignore_global ~/.config/nvim ~/.config/ghostty/config \
         ~/.config/ghostty/themes ~/.config/zed/settings.json ~/.config/zed/keymap.json \
         ~/.config/jj/config.toml ~/.hammerspoon ~/.config/sketchybar ~/.yabairc ~/.skhdrc \
         "$HOME/Library/Application Support/lazygit" \
         "$HOME/Library/Application Support/com.mitchellh.ghostty/config"; do
  if [ -L "$l" ]; then echo "  symlink: $l"
  elif [ -e "$l" ]; then echo "  NOT A SYMLINK: $l"
  else echo "  MISSING: $l"; fi
done
```
Expected: every line `symlink:`. Anything else is a regression in this refactor.

- [ ] **Step 4: Confirm the shell and git both still work**

```bash
zsh -ic 'exit' && echo "  zshrc loads"
git config --get user.email
cd ~/Code/dotfiles && git status --short
```
Expected: `zshrc loads`, the right email, and a clean tree.

- [ ] **Step 5: Remove the abandoned July worktree**

```bash
cd ~/Code/dotfiles
git worktree remove .claude/worktrees/macos-only-dotfiles-dcf0a3 --force
git worktree list
```
Expected: only the main checkout remains.

- [ ] **Step 6: Push and release**

```bash
cd ~/Code/dotfiles
git push origin main
./release 2.0.0
gh release view v2.0.0 --json name,tagName
```

---

## Deferred / not in scope

- **`.claude/settings.local.json`** contains stale allowlist entries naming `shared/…`, `mac/…`, and `buildghostty.sh`. They are inert permission strings, not code, so they are left alone; clean them up separately if the noise matters.
- **`brew "openvpn"` in the merged Brewfile.** The openvpn formula is currently uninstalled and its orphaned launchd daemon was pruned in v1.2.0, but the Brewfile still lists it — so `./setup` on this machine would reinstall it and could re-create the daemon. Decide separately whether to drop the entry; it is pre-existing behaviour, not something the flatten changes.
- **Font delivery stays a copy.** Symlinked fonts in `~/Library/Fonts` are not reliably activated by macOS `fontd`, and this refactor does not test that. Left as-is.
