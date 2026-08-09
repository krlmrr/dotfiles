---
name: project_laravel_lsp_zed
description: Laravel LSP runs in Zed as a dev extension pending PR #6996; revert the rustup dotfiles changes once it's in the marketplace
metadata:
  type: project
---

Laravel's official LSP (`laravel/lsp`, announced at Laracon US 2026) is running in Zed as a **dev extension**, installed 2026-07-28 from a clone of `laravel/zed-extension` at `~/Code/laravel-zed-extension` (commit `23f7e06`). It is NOT from the marketplace — [zed-industries/extensions#6996](https://github.com/zed-industries/extensions/pull/6996) repoints the existing `laravel` registry entry from `mike-bronner/zed-laravel` to Laravel's repo (0.6.0 → 0.7.0) and was still open as of 2026-07-28.

**Why it needed manual work:** Zed compiles dev extensions to `wasm32-wasip2` and only a rustup-managed toolchain can add targets. Homebrew's `rustup` formula is keg-only (collides with the `rust` formula, which links its own cargo/rustc into `/opt/homebrew/bin`); with both installed, Zed ran rustup's `target add` successfully and then compiled with brew rust's cargo, failing with a misleading "target may not be installed". Fixed with `brew unlink rust && brew link --force --overwrite rustup` — that state is live on the machine, reversible via `brew unlink rustup && brew link rust`. Note Zed's own process inherits launchd's PATH, not `.zshrc`, so shell PATH edits can't fix extension builds.

**⚠️ #6996 IS CONTESTED — DON'T WAIT ON IT (updated 2026-07-29).** The PR repoints the shared `laravel` submodule from `mike-bronner/zed-laravel` → `laravel/zed-extension`, i.e. it takes over the existing listing rather than adding a new one. Mike Bronner objected (hundreds of hours, no prior contact, feature regressions), Laravel (@joetannenbaum) apologized for the abrupt PR, and Zed (@MrSubidubi) said they only replace extensions "if there is consensus or inactivity" — neither applies — and personally vouched for Mike. **Mike's stated position: close #6996 and have Laravel register its own separate extension.** Most likely outcome is therefore CLOSED, not merged.

**🚨 THE TRAP in the old plan:** if Laravel registers separately, the marketplace entry named **“Laravel” will still be Mike's community extension**, NOT the official LSP. Blindly doing "uninstall dev extension → install Laravel from marketplace" would silently swap to a *different language server with a different architecture*. Check the publisher/repo before installing.

**Consequences while this is unresolved:** the dev extension never auto-updates, so this machine is frozen at `23f7e06` and needs a manual `git pull` + rebuild in `~/Code/laravel-zed-extension` for LSP updates — and the parked rustup provisioning in `mac/Brewfile` + `mac/setup.sh` must **stay** (don't `git checkout` it yet).

**The real decision (not just a waiting game):** official `laravel/lsp` boots the app via `artisan tinker --execute` (needs a bootable app; Herd is fine on this Mac) and per Mike's capability audit implements **no rename, no find-references, no code lens, no document symbols** — consistent with the "no go-to-definition" note below. Mike's `zed-laravel` is pure tree-sitter static analysis (works on broken/dirty apps, package repos with no bootable root), has rename + find-references + outline + code lens, ships precompiled wasm (**no rustup at all**), and auto-updates. Official wins on Mix, auth/policies, Storage disks, Pest. Neither is a superset.

**How to apply — IF #6996 ever merges:**
1. Uninstall the dev extension in Zed, then install **Laravel** from the marketplace (dev extensions never auto-update) — verifying it resolves to `laravel/zed-extension`.
2. `git checkout mac/Brewfile mac/setup.sh` — the parked rustup provisioning (uncommitted as of 2026-07-28) becomes unnecessary, since marketplace extensions ship precompiled wasm and need no Rust toolchain. Keep it only if rustup is wanted for other reasons.
3. Optionally `composer global remove laravel/lsp` — the global v0.0.28 binary is unused by Zed (the extension downloads and manages its own copy); kept in case a Neovim setup wants it.

Features arrive as document links, completions, hovers, diagnostics and code actions — there is **no** go-to-definition provider, so Cmd+click works and F12 does nothing. Inertia is fully supported (page/property completions, links, diagnostics). See [[user_editor_choice]].
