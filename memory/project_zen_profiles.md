---
name: zen-profiles
description: Karl runs two Zen browser profiles to separate work (NotaryDash) from personal — different password managers per profile
metadata:
  type: project
---

Karl runs two Zen profiles on his Mac:

- **Home** — personal, default profile. Uses **1Password**. This is his long-term profile (since ~Arc shutdown) with all his customizations, keybindings, Zen Mods, and history.
- **NotaryDash** — work profile, created 2026-05. Uses **ProtonPass** (NotaryDash-mandated). Customizations were migrated from Home (`chrome/`, `zen-themes.json`, `zen-keyboard-shortcuts.json`, `xulstore.json`, plus `zen.*` and `browser.uiCustomization.state` prefs).

Profile directories:
- `~/Library/Application Support/zen/Profiles/0adh67j4.Default (release)` = Home
- `~/Library/Application Support/zen/Profiles/ajh344nj.NotaryDash` = NotaryDash

**Why:** Karl joined NotaryDash 2026-03 and wants hard separation between work and personal browsing — different password managers, separate cookies/sessions, no overlap. Tried single-profile-with-both-extensions; rejected because both vaults would surface on shared sites like GitHub. Real Firefox profiles is the only mechanism that gives true extension isolation.

**How to apply:** Launching NotaryDash uses `~/Documents/zen-nd.sh` (Raycast script command). Clicking Zen normally opens Home. Don't suggest merging the profiles or scoping extensions by site — that ground was covered and rejected. When making Zen-related changes, ask which profile or apply to both.
