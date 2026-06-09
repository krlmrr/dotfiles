## User
- [Mac is home; pull in the COSMIC ergonomics that matter](user_cross_platform_goal.md) — Mac is the long-term daily-driver, not a stopgap. Borrow COSMIC's coding ergonomics; leave non-coding macOS surface area alone.

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

## Project
- [yabai: never restart-service on wake](project_yabai_wake_no_restart.md) — restart-on-wake caused all post-wake breakage; sleep changes nothing. No system_woke signal; display events gated by display-changed.sh
- [yabai SIP-on test on macOS 27 beta](project_yabai_sip_on_test.md) — Karl testing yabai without SA on a "Beta" volume; if asked there, build a SIP-on yabairc variant (no --load-sa, drop cross-space binds, lean on native spaces)
- [Migrating Linux PHP dev to Lerd (podman)](project_lerd_migration.md) — Docker + DDEV removed on 2026-05-13. Lerd not yet wired in; `a`/`d`/`lzd` aliases left as TODO markers.
- [Two Zen profiles: Home + NotaryDash](project_zen_profiles.md) — Personal (1Password) vs work (ProtonPass); hard isolation via real Firefox profiles
- [Synology homelab on vheissulabs.com](project_homelab_synology.md) — DS1618+ runs Docker services (GitLab, Pi-hole) behind DSM reverse proxy + acme.sh wildcard cert; tailnet-private via CGNAT
