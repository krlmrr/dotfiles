---
name: lerd-replacing-ddev-on-linux
description: "User is migrating Linux PHP dev from DDEV/Docker to Lerd (podman-based Laravel local-dev tool). Docker and DDEV were removed from dotfiles on 2026-05-13; Lerd not yet wired in."
metadata:
  type: project
---

**Fact.** On 2026-05-13 the user pulled Docker and DDEV out of the dotfiles — install steps, repo files, mkcert, `sg docker` config, `nvidia-container-toolkit --runtime=docker`, and `lazydocker` from `linux/Brewfile`. Plan is to replace with **Lerd**, a Laravel local-dev tool built on **podman** (not Herd-for-Linux, which they were watching for earlier).

The `a` alias in `linux/shared/zsh/aliases.sh` still points at `ddev artisan` — left in place as a TODO marker since the user hasn't decided what it should map to yet under Lerd. Same for the `d="ddev"` and `lzd="lazydocker"` aliases — also untouched, also broken until Lerd lands or the aliases get removed.

**Why:** Earlier plan was Herd-for-Linux (native, Docker-free, would unify with Mac). That's not what shipped — Lerd is a different tool with podman under the hood. User is moving anyway because DDEV/Docker is a friction point they want gone.

**How to apply:**
- Don't suggest Docker- or DDEV-specific tooling for Linux dev anymore. They're out.
- Don't suggest re-adding `lazydocker` unless paired with a podman docker-compat socket. `podman-tui` is the cleaner equivalent if a TUI comes back up.
- The `a`/`d`/`lzd` aliases will need re-targeting once Lerd is installed. Don't change them preemptively.
- If the user mentions installing Lerd, that's the trigger to wire it into `linux/fedora/setup.sh` and re-decide the alias.
- Mac side (Herd) is unchanged.
