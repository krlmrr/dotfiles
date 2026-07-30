## User
- [Mac is home; pull in the COSMIC ergonomics that matter](user_cross_platform_goal.md) — Mac is the long-term daily-driver, not a stopgap. Borrow COSMIC's coding ergonomics; leave non-coding macOS surface area alone.
- [Editors: VS Code or Zed only](user_editor_choice.md) — JetBrains/PhpStorm dropped for good (removed 2026-07-06); don't reintroduce it.

## Feedback
- [Don't nerd-snipe toward Linux/Framework](feedback_no_linux_nerd_snipe.md) — Karl is committing to Mac; don't suggest Linux/Framework alternatives or romanticize the other side.
- [No sleep, no guessing timings](feedback_no_sleep.md) — Don't use sleep/delays to fix timing issues, find the real solution
- [Stop guessing, listen to the user](feedback_stop_guessing.md) — Think before cycling through random fixes, listen to what the user is saying
- [No time/duration estimates](feedback_no_time_estimates.md) — Don't say "an afternoon", "2 weeks", "10 minutes" — describe scope by structure, not wall-clock time
- [Never killall Dock from Hammerspoon](feedback_killall_dock.md) — Use external shell scripts for killall Dock, never inline in hs.execute
- [Release script auto-prefixes v](feedback_release_script.md) — ./release accepts 1.0.XX or v1.0.XX; either works
- [Review skills before committing](feedback_review_before_commit.md) — Always review changes against coding skills BEFORE git commit/push
- [Yabai space 2 is intentionally unmanaged](feedback_yabai_space2.md) — Space 2 is float layout (chat apps); never touch it in window logic or diagnostics
- [Yabai display event semantics](feedback_yabai_display_events.md) — display_changed fires on focus crossing screens; use display_added/removed/moved/resized for hardware reconfig
- [Don't suggest AeroSpace](feedback_no_aerospace.md) — User evaluated and rejected AeroSpace; needs native macOS spaces. Fix yabai pain inside yabai, don't pitch alternatives.
- [Raycast is the launcher](feedback_raycast_launcher.md) — Karl uses Raycast for launching apps and shell actions; prefer Raycast script commands over zsh aliases
- [Clean up remote temp state](feedback_cleanup_remote_state.md) — Don't trust `--rm` under signal kills; verify and clean up containers/files/processes I create on remote hosts before declaring done
- [Minimal comments](feedback_minimal_comments.md) — Don't add explanatory comment blocks just because code changed; make the minimal edit
- [Key chords as cmd+X, never cmd-X](feedback_keybinding_notation.md) — Font ligatures turn `->` into `→`; hyphen-separated chords get misread as arrow keys

## Project
- [yabai: never restart-service on wake](project_yabai_wake_no_restart.md) — restart-on-wake caused all post-wake breakage; sleep changes nothing. No system_woke signal; display events gated by display-changed.sh
- [yabai SIP-on test on macOS 27 beta](project_yabai_sip_on_test.md) — Karl testing yabai without SA on a "Beta" volume. v7.1.25 (#2788) makes `window --space` work SIP-on; `space --focus` still needs SA. No-SA branch can regain window-to-space binds pending live test on Golden Gate.
- [Migrating Linux PHP dev to Lerd (podman)](project_lerd_migration.md) — Docker + DDEV removed on 2026-05-13. Lerd not yet wired in; `a`/`d`/`lzd` aliases left as TODO markers.
- [yabai: Zen PiP masquerades as AXStandardWindow](project_yabai_pip_masquerade.md) — PiP popout reports AXStandardWindow + is-sticky; hijacked win_id → random red insert-overlay box + wrong editor layout. Fixed by excluding PiP by title in win_id/external_correct/move.
- [Two Zen profiles: Home + NotaryDash](project_zen_profiles.md) — Personal (1Password) vs work (ProtonPass); hard isolation via real Firefox profiles
- [Laravel LSP in Zed via dev extension](project_laravel_lsp_zed.md) — pending PR #6996; when it merges, swap to the marketplace extension and revert the parked rustup changes in mac/Brewfile + mac/setup.sh
- [yabai --insert parity trap](project_yabai_insert_parity.md) — armed points survive warps; never prime, verify+repair instead
- [yabai browser array + incremental placement](project_yabai_browser_incremental.md) — Zen-hardcode in external_correct caused the constant misplacement/restarts (fixed by BROWSER_APPS); place_one moves only the new window on open; zero-motion impossible (window_created fires post-BSP); daily driver is the Studio Display (3200×1800 scaled), LAPTOP_W/H=2056×1329 is CORRECT; Apple TV casting can transiently scramble the trio (not handled, rare)
- [jj git init --colocate scrambled .git/index](project_jj_colocate_index.md) — phantom Added/Deleted entries git-side after colocating; HEAD/refs/files unaffected; repair via `rm -f .git/index && git read-tree HEAD` (check for real staged changes first)
- [jj conf.d layers over config.toml](project_jj_config_layering.md) — verified on jj 0.43.0; underpins the symlinked config.toml + generated conf.d/00-identity.toml split; jj skips git hooks so jj-made commits bypass the Brewfile-sorting pre-commit hook
