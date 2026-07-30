---
name: project_jj_colocate_index
description: jj git init --colocate can leave a scrambled .git/index that git misreads as phantom changes; repair is index-only
metadata:
  type: project
---

Running `jj git init --colocate` in this dotfiles repo (2026-07-29) left `.git/index` in a state git itself mis-read: `git status` / `git diff --cached` reported phantom Added/Deleted entries for files that were simultaneously present in HEAD and unmodified on disk. Some of the scrambled index entries pointed at git's empty blob (`e69de29b...`) — i.e. intent-to-add records for files that had been untracked before colocation. HEAD, branch refs, and actual file contents were **not** affected; this was purely an index artifact.

**Repair is index-only:** `rm -f .git/index && git read-tree HEAD`. Verified one-time and self-limiting — the index stayed clean across subsequent `jj st` / `jj log` / `jj diff` in this repo.

**Why this matters for future colocation:** in this repo nothing was staged when it happened, so the repair was safe (rebuilding the index from HEAD loses nothing). If a future `jj git init --colocate` on a repo with staged-but-uncommitted git changes hits the same scrambling, blindly doing `rm -f .git/index && git read-tree HEAD` would discard that staged work. Check `git diff --cached` for anything real before repairing.
