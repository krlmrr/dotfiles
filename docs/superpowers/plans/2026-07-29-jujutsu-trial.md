# Jujutsu (jj) Trial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install `jj` + `lazyjj` via the dotfiles, deliver a minimal symlinked jj config with a generated (uncommitted) identity, add shell aliases, and colocate jj into this dotfiles repo without displacing git.

**Architecture:** Four independent changes to existing files plus one new config file. `shared/Brewfile` installs on both platforms. `shared/jj/config.toml` is **symlinked** so edits are live. The machine-specific identity is **generated** by `configure` into `~/.config/jj/conf.d/` and never committed — this is the one design decision resting on an unverified assumption, so Task 1 gates on proving it.

**Tech Stack:** Homebrew (`jj` 0.43.0, `lazyjj` 0.6.1), bash (`configure`, `buildzshrc`), TOML, zsh aliases.

**Spec:** `docs/superpowers/specs/2026-07-29-jujutsu-trial-design.md`

## Global Constraints

- Editor is `nvim`, never `zed --wait` — a transient Zed window would be placed by yabai's editor-array logic.
- `shared/Brewfile` entries stay in alphabetical order.
- `shared/jj/config.toml` stays minimal: **no** revset aliases, **no** `ui.default-command`, **no** diff/merge tool config.
- The jj identity must never be committed to the repo.
- `configure` runs under `set -e`. Use `if` blocks, not `[ -n "$X" ] && cmd` chains, for anything that could be the last statement in a block.
- `link()` (from `shared/functions.sh`) already does `mkdir -p "$(dirname "$2")"`, `rm -rf` then `ln -snf`. Do not add a redundant `mkdir` before a `link` call.
- `.zshrc` is a **built** config — every `shared/zsh/aliases.sh` edit requires `./buildzshrc`.
- Touch only: `shared/Brewfile`, `shared/jj/config.toml` (new), `configure`, `shared/zsh/aliases.sh`, `shared/git/gitignore_global`. No other repo.
- The repo has a `pre-commit` hook at `shared/git/hooks/pre-commit`; commits may run it. If it fails, fix the cause — do not use `--no-verify`.
- The working tree has many unrelated modified files. **Stage only the files named in each task's commit step.** Never `git add -A` or `git add .`.

---

### Task 1: Install jj + lazyjj, and verify the `conf.d` assumption

This task is a gate. The spec's identity design assumes `~/.config/jj/conf.d/*.toml` **layers on top of** `config.toml`. Prove or disprove it here, before any of it is wired into `configure`.

**Files:**
- Modify: `shared/Brewfile` (insert after line 16 `brew "imagemagick"`, and after line 17 `brew "lazygit"`)

**Interfaces:**
- Consumes: nothing.
- Produces: working `jj` and `lazyjj` binaries on PATH; a verified answer to the conf.d question that Task 2 branches on.

- [ ] **Step 1: Add both formulae in alphabetical position**

`shared/Brewfile` currently reads (lines 16-18):

```ruby
brew "imagemagick"
brew "lazygit"
brew "luarocks"
```

Make it read:

```ruby
brew "imagemagick"
brew "jj"
brew "lazygit"
brew "lazyjj"
brew "luarocks"
```

- [ ] **Step 2: Install**

Run: `brew bundle --file=shared/Brewfile`
Expected: installs `jj` and `lazyjj`; everything else already satisfied.

- [ ] **Step 3: Confirm both binaries work**

Run: `jj --version && lazyjj --version`
Expected: `jj 0.43.0` (or newer) and `lazyjj 0.6.1` (or newer). Non-zero exit means stop and fix before continuing.

- [ ] **Step 4: Probe the conf.d layering assumption**

This is the whole point of the task. Create both files by hand, with a distinct value in each, and see whether **both** survive:

```bash
mkdir -p ~/.config/jj/conf.d
printf '[ui]\neditor = "probe-from-config-toml"\n' > ~/.config/jj/config.toml
printf '[user]\nname = "Probe Person"\nemail = "probe@example.com"\n' > ~/.config/jj/conf.d/00-identity.toml
jj config list --include-defaults | grep -E 'ui\.editor|user\.name|user\.email'
```

Expected if the assumption **holds** — all three present:

```
ui.editor = "probe-from-config-toml"
user.name = "Probe Person"
user.email = "probe@example.com"
```

If instead `user.name`/`user.email` are missing, or `ui.editor` is missing, the files are **not** layering. Also run `jj help config` and read the config-file precedence section to confirm which paths this jj version actually reads.

- [ ] **Step 5: Record the verdict, then clean up the probe**

Write the outcome into the plan file under this step — one line, e.g. `VERDICT: conf.d layers on top of config.toml (confirmed on jj 0.43.0)` or `VERDICT: conf.d not read; falling back to copy+inject`. Task 2 reads this line.

Then remove the probe files so Task 2 starts from a clean state:

```bash
rm -rf ~/.config/jj
```

- [ ] **Step 6: Commit**

```bash
git add shared/Brewfile
git commit -m "brew: add jj and lazyjj"
```

---

### Task 2: Shared config, symlink, and generated identity

**Files:**
- Create: `shared/jj/config.toml`
- Modify: `configure` (add a jj block after the zed block ending at line 44)

**Interfaces:**
- Consumes: Task 1's VERDICT line, which selects between branch A and branch B in Step 3. Requires `jj` on PATH.
- Produces: `~/.config/jj/config.toml` (symlink to the repo) and a jj identity resolvable by `jj config list`. Task 4's `jj git init --colocate` depends on the identity existing.

- [ ] **Step 1: Create the shared config**

Create `shared/jj/config.toml` with exactly this content — nothing more:

```toml
[ui]
editor = "nvim"
```

- [ ] **Step 2: Verify it is not yet in effect**

Run: `test -e ~/.config/jj/config.toml && echo PRESENT || echo ABSENT`
Expected: `ABSENT` — Task 1 Step 5 removed it, and `configure` has not been touched yet. This is the "failing test": the config exists in the repo but is not delivered.

- [ ] **Step 3: Wire it into `configure`**

**Branch A — use this if Task 1's VERDICT confirmed conf.d layering.**

In `configure`, immediately after the zed `fi` on line 44 and before the blank line preceding `# Claude Code skills`, insert:

```bash
# Jujutsu — config.toml is symlinked (live), but jj refuses to commit without an
# identity and that is machine-specific, so generate it into conf.d/ from the git
# identity instead of committing it.
link "$DOTFILES_DIR/shared/jj/config.toml" ~/.config/jj/config.toml
if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
    mkdir -p ~/.config/jj/conf.d
    cat > ~/.config/jj/conf.d/00-identity.toml <<EOF
# generated by ./configure — do not edit
[user]
name = "$GIT_NAME"
email = "$GIT_EMAIL"
EOF
fi
```

`GIT_NAME` and `GIT_EMAIL` are already set at `configure:10-11`, so no re-read is needed. The `if` guard means a fresh machine with no git identity gets no half-written file. Note the heredoc is unquoted (`<<EOF`) so the variables expand — this is intentional.

**Branch B — use this only if Task 1's VERDICT says conf.d is not read.** Replace the two `link`/`if` lines above with a copy-and-inject, mirroring the `.gitconfig` pattern at `configure:12-17`:

```bash
# Jujutsu — copied, not symlinked: the identity is machine-specific and jj reads a
# single config.toml, so it must be appended after the copy. Editing
# shared/jj/config.toml requires a ./configure re-run.
mkdir -p ~/.config/jj
cp "$DOTFILES_DIR/shared/jj/config.toml" ~/.config/jj/config.toml
if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
    cat >> ~/.config/jj/config.toml <<EOF

# generated by ./configure — do not edit
[user]
name = "$GIT_NAME"
email = "$GIT_EMAIL"
EOF
fi
```

If branch B is used, also update the delivery-mode table in `CLAUDE.md` — move jj from the symlinked row to the copied row — and say so in the final report.

- [ ] **Step 4: Run configure and verify delivery**

Run: `./configure`
Expected: completes, ending in `Done!`.

Then, for branch A:

```bash
readlink ~/.config/jj/config.toml
cat ~/.config/jj/conf.d/00-identity.toml
jj config list --include-defaults | grep -E 'ui\.editor|user\.name|user\.email'
```

Expected: the `readlink` prints the repo path `…/dotfiles/shared/jj/config.toml`; the identity file shows the real name/email; and the `jj config list` output shows `ui.editor = "nvim"` **plus** the real `user.name` and `user.email`. That last line is the proof the whole identity design works.

For branch B: `~/.config/jj/config.toml` is a regular file (`readlink` prints nothing, exit 1) containing both the `[ui]` and `[user]` sections, and the same `jj config list` grep shows all three values.

- [ ] **Step 5: Verify idempotency**

Run: `./configure && ./configure`
Then re-run the Step 4 verification commands.
Expected: identical output. Specifically, `00-identity.toml` (branch A) must not have grown, and in branch B `grep -c '^\[user\]' ~/.config/jj/config.toml` must print `1`, not `2` — a repeated append is the likely bug here.

- [ ] **Step 6: Commit**

```bash
git add shared/jj/config.toml configure
git commit -m "jj: symlink shared config, generate identity from git config"
```

(If branch B was used, add `CLAUDE.md` to that `git add` and use the message `jj: copy shared config, inject identity from git config`.)

---

### Task 3: Shell aliases

**Files:**
- Modify: `shared/zsh/aliases.sh` (the `# Tools` block, lines 8-11)

**Interfaces:**
- Consumes: `jj` and `lazyjj` on PATH from Task 1.
- Produces: aliases `lzj`, `js`, `jl`, `jd`, `jn` in the built `.zshrc`.

- [ ] **Step 1: Confirm no name collisions**

Run: `for a in lzj js jl jd jn; do printf '%s: ' "$a"; command -v "$a" || echo "(free)"; done`
Expected: all report `(free)`. If any resolves to an existing command or alias, stop and report it rather than shadowing it silently.

- [ ] **Step 2: Add the Jujutsu block**

`shared/zsh/aliases.sh` lines 8-11 currently read:

```bash
# Tools
alias lzg="lazygit"
alias yeet="sudo rm -rf"
alias mkd="mkdir -p"
```

Make it read:

```bash
# Tools
alias lzg="lazygit"
alias yeet="sudo rm -rf"
alias mkd="mkdir -p"

# Jujutsu
alias lzj="lazyjj"
alias js="jj status"
alias jl="jj log"
alias jd="jj diff"
alias jn="jj new"
```

- [ ] **Step 3: Rebuild `.zshrc`**

Run: `./buildzshrc`
Expected: completes without error. `.zshrc` is a built config — editing the source alone changes nothing.

- [ ] **Step 4: Verify the aliases landed**

Run: `grep -nE 'alias (lzj|js|jl|jd|jn)=' ~/.zshrc`
Expected: all five lines present.

Then confirm they resolve in a real shell:

Run: `zsh -ic 'alias js jl jd jn lzj'`
Expected: five alias definitions echoed back, e.g. `js='jj status'`.

- [ ] **Step 5: Commit**

```bash
git add shared/zsh/aliases.sh
git commit -m "zsh: add jj aliases"
```

---

### Task 4: Ignore `.jj/` and colocate this repo

**Files:**
- Modify: `shared/git/gitignore_global` (append after line 20 `.ddev/`)
- Creates untracked: `.jj/` in the repo root (not committed)

**Interfaces:**
- Consumes: `jj` on PATH (Task 1) and a working identity (Task 2) — `jj` cannot create the initial commit without it.
- Produces: a colocated repo where both `jj` and `git` operate on the same history.

- [ ] **Step 1: Add `.jj/` to the global ignore**

`shared/git/gitignore_global` lines 17-20 currently end:

```
.lvimrc
.projections.json
.phpactor.json
.ddev/
```

Add `.jj/` after `.ddev/`:

```
.lvimrc
.projections.json
.phpactor.json
.ddev/
.jj/
```

`gitignore_global` is symlinked to `~/.gitignore_global`, so this takes effect immediately with no rebuild.

- [ ] **Step 2: Verify the ignore is live before creating `.jj/`**

Run: `git check-ignore -v .jj/`
Expected: a line naming `~/.gitignore_global` and the `.jj/` pattern. Confirming this **before** colocating means `.jj/` never has a chance to show up as untracked.

- [ ] **Step 3: Record the pre-colocation git state**

Run: `git rev-parse HEAD && git status --porcelain | wc -l`
Expected: some commit SHA and a count of modified files. Save both — Step 6 compares against them to prove colocation did not disturb git.

- [ ] **Step 4: Colocate**

Run: `jj git init --colocate`
Expected: a message about initialising an existing Git repo. This creates `.jj/` and leaves `.git` in place and authoritative.

- [ ] **Step 5: Verify jj sees the repo**

Run: `jj st && jj log -r '::@' --limit 5`
Expected: `jj st` lists the working-copy changes (it will show the many unrelated modified files as changes to the working-copy commit — that is normal and correct for colocation, not a bug to fix). `jj log` shows recent history including the commits from Step 3.

- [ ] **Step 6: Verify git is undisturbed — the critical check**

```bash
git rev-parse HEAD
git status --porcelain | wc -l
git status --porcelain | grep -F '.jj' || echo "GOOD: .jj not listed"
```

Expected: the same SHA and the same file count as Step 3, and `GOOD: .jj not listed`. Any difference means colocation altered git state — stop and report rather than proceeding.

Also confirm the TUI opens against the real repo:

Run: `lazyjj` (then quit with `q`)
Expected: it renders the log without erroring. If it fails, report it — this is informational, not a reason to roll back the colocation.

- [ ] **Step 7: Commit**

```bash
git add shared/git/gitignore_global
git commit -m "git: ignore .jj/ globally"
```

`.jj/` itself is intentionally never committed.

---

## Final verification

Run all of these and paste real output — no claims without it:

```bash
jj --version && lazyjj --version
jj config list --include-defaults | grep -E 'ui\.editor|user\.name|user\.email'
readlink ~/.config/jj/config.toml   # branch A only; empty for branch B
jj st
git status --porcelain | grep -F '.jj' || echo "GOOD: .jj not tracked"
zsh -ic 'alias js jl jd jn lzj'
git log --oneline -4
```

Then confirm the four commits exist and that no unrelated working-tree files were staged: `git show --stat --oneline HEAD~3..HEAD` should touch only `shared/Brewfile`, `shared/jj/config.toml`, `configure`, `shared/zsh/aliases.sh`, `shared/git/gitignore_global` (plus `CLAUDE.md` if branch B).

## Rollback

```bash
rm -rf .jj                                    # undo colocation; .git untouched
brew uninstall jj lazyjj
rm -rf ~/.config/jj
git revert <the four commits>                  # or reset if unpushed
./buildzshrc                                   # rebuild .zshrc without the aliases
```
