# Claude Notes

## Overview

This is Karl's dotfiles repo. He's a Laravel (VILT/TALL stack) developer who prefers Neovim-style keybindings across all editors.

## VS Code Setup

VS Code has been heavily customized to feel more like Neovim:

- **Custom CSS/JS**: Located in `vscode/custom.css` and `vscode/custom.js`
  - Fading scrollbars (only visible when actively scrolling)
  - Hidden horizontal scrollbar
  - Rounded vertical scrollbar with padding
  - Status bar tweaks (no backgrounds, padding, hidden git icon)
  - JS uses `requestIdleCallback` to defer setup and not block VS Code boot
- **Terminal quirk**: Line height >1.4 causes a rendering bug where empty space appears at top instead of bottom. Keep `terminal.integrated.lineHeight` at 1.4 or below.
- **Keybindings**: Most default VS Code shortcuts have been removed in favor of Neovim-style bindings
  - `<leader>e` - Toggle sidebar/explorer
  - `<leader>t*` - Test commands (ta=all, tl=last, tc=cursor, tf=file)
  - Uses VSCode Neovim extension

## Neovim Setup

- Plugin manager: lazy.nvim (`:Lazy` command, no keybinding)
- `<leader>gg` - LazyGit
- `<leader>pt` - Run Pest tests in parallel
- Config in `nvim/` directory

## Ghostty

Terminal emulator config in `ghostty/config`. Uses custom themes.

## QMK Keyboard (Lily58)

Custom keymap at `~/qmk_firmware/keyboards/lily58/keymaps/krlmrr/`

- **Layers**: QWERTY (macOS), WIN, LIN, GAME, LOWER, RAISE, ADJUST
- **Layer switching**: RAISE + 1/2/3/4 for macOS/Win/Linux/Game layers
  - Layers persist across reboots via `set_single_persistent_default_layer()`
  - Layer switch only takes effect on RAISE release (can press multiple, last one wins)
- **Game layer**: Plain `KC_SPC` instead of mod-tap - fixes issues where hold+space triggers CMD/CTRL in games
- **Mod-tap space**: On non-game layers, space is `MT(MOD_LGUI, KC_SPC)` (macOS) or `MT(MOD_LCTL, KC_SPC)` (Win/Lin)
- **OLED**: Left side shows current layer name, active modifiers, WPM, caps word status
- **RGB**: Disabled to save firmware space (~3.5KB saved)

Build: `qmk compile -kb lily58 -km krlmrr`
Flash: `qmk flash -kb lily58 -km krlmrr`

## Projects

- **VheissuLabs**: Karl's company for developer tools
- **Beggars Theme**: VS Code + Ghostty theme based on Thrice's album art (separate repo at ~/code/beggars-theme)
- **Vheissu**: Karl's vim-inspired editor built in Zig with raylib (at ~/code/Vheissu)

## Preferences

- Uses light themes situationally (bright rooms), not a light mode purist
- Thrice fan (album-inspired naming: Vheissu, Beggars)
- Minimal UI - prefers keyboard shortcuts over visible UI elements
- No emojis unless explicitly requested
- Games on Windows (Destiny 2) - reason for the dedicated Game layer on keyboard
