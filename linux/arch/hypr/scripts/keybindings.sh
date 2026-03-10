#!/bin/bash

# Display keybindings in rofi
keybindings="--- Hyprland ---
Hyprland: Super + Return — Terminal
Hyprland: Super + Q — Close Window
Hyprland: Super + Space — App Launcher
Hyprland: Super + E — File Manager
Hyprland: Super + B — Zen Sidebar (Ctrl+S)
Hyprland: Super + V — Toggle Floating
Hyprland: Super + M — Exit Hyprland

--- Workspaces ---
Workspace: Super + 1-9 — Switch Workspace
Workspace: Super + Shift + 1-9 — Move Window
Workspace: Super + Scroll — Cycle Workspaces

--- Focus & Move ---
Focus: Super + H/L — Focus Monitor Left/Right
Focus: Super + Shift + H/L — Move Window to Monitor
Focus: Super + Arrow Keys — Move Focus

--- Mac-like Shortcuts ---
Mac: Super + C — Copy
Mac: Super + V — Paste
Mac: Super + X — Cut
Mac: Super + Z — Undo
Mac: Super + Shift + Z — Redo
Mac: Super + A — Select All
Mac: Super + S — Save
Mac: Super + F — Find
Mac: Super + W — Close Tab
Mac: Super + T — New Tab
Mac: Super + N — New
Mac: Super + O — Open
Mac: Super + P — Print
Mac: Super + R — Refresh

--- Tmux (prefix: Ctrl+A) ---
Tmux: Ctrl+A c — New Window
Tmux: Ctrl+A n/p — Next/Previous Window
Tmux: Ctrl+A 1-9 — Switch to Window
Tmux: Ctrl+A | — Split Horizontal
Tmux: Ctrl+A - — Split Vertical
Tmux: Ctrl+A h/j/k/l — Navigate Panes
Tmux: Ctrl+A Ctrl+h/j/k/l — Resize Panes
Tmux: Ctrl+A r — Reload Config
Tmux: Ctrl+A d — Detach Session
Tmux: Ctrl+A s — List Sessions
Tmux: Ctrl+A :new -s name — New Session

--- Other ---
Other: Capslock (tap) — Escape
Other: Capslock (hold) — Control"

echo "$keybindings" | rofi -dmenu -p "Keybindings" -i -theme-str 'window {width: 600px;}'
