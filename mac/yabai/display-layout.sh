#!/usr/bin/env sh
# Position Zen, Zed, and Ghostty based on whether the external display is present.
#
# External present (lid open dual-display OR clamshell with external only):
#   All on external's 3rd space, tiled as:
#       +---------+---------+
#       |   Zen   |         |
#       +---------+   Zed   |
#       | Ghostty |         |
#       +---------+---------+
#
# Laptop only:  Zen → space 3, Zed → 4, Ghostty → 5.
#
# Display identified by frame size (stable across plug/unplug/clamshell).
# MBP 16" reports 2056x1329 in yabai's points; adjust if the laptop changes.

PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

LAPTOP_W=2056
LAPTOP_H=1329

# Move all windows of app $1 to space $2.
move() {
  yabai -m query --windows 2>/dev/null \
    | jq -r --arg a "$1" '.[] | select(.app == $a) | .id' \
    | xargs -I{} yabai -m window {} --space "$2" 2>/dev/null
}

# Get "<id>|<frame.x>" for the first window of app $1 on space $2.
window_info() {
  yabai -m query --windows 2>/dev/null \
    | jq -r --arg a "$1" --argjson s "$2" \
      '.[] | select(.app == $a and .space == $s) | "\(.id)|\(.frame.x)"' \
    | head -1
}

# External = the display whose frame isn't the laptop's.
external_idx=$(yabai -m query --displays \
  | jq -r --argjson w "$LAPTOP_W" --argjson h "$LAPTOP_H" \
    '.[] | select(.frame.w != $w or .frame.h != $h) | .index' \
  | head -1)

if [ -n "$external_idx" ]; then
  target=$(yabai -m query --spaces --display "$external_idx" 2>/dev/null \
            | jq -r '.[2].index // empty')
  [ -z "$target" ] && exit 0

  move Zen "$target"
  move Zed "$target"

  # Enforce Zen-left / Zed-right. `--warp A B` puts A in first/west position;
  # `--swap` would also work but silently no-ops unless the space is focused.
  zen=$(window_info Zen "$target")
  zed=$(window_info Zed "$target")
  zen_id="${zen%%|*}"
  if [ -n "$zen" ] && [ -n "$zed" ]; then
    if awk -v z="${zed##*|}" -v n="${zen##*|}" 'BEGIN{exit !(z<n)}'; then
      yabai -m window "$zen_id" --warp "${zed%%|*}" 2>/dev/null
    fi
  fi

  # Ghostty bottom-left: two warps to deterministically place south of Zen.
  # `--warp Ghostty Zen` makes them siblings (Ghostty north); the second warp
  # flips order so Zen is north (top) and Ghostty is south (bottom).
  ghostty_id=$(yabai -m query --windows 2>/dev/null \
    | jq -r '.[] | select(.app == "Ghostty") | .id' | head -1)
  if [ -n "$ghostty_id" ] && [ -n "$zen_id" ]; then
    yabai -m window "$ghostty_id" --space "$target" 2>/dev/null
    yabai -m window "$ghostty_id" --warp "$zen_id" 2>/dev/null
    yabai -m window "$zen_id" --warp "$ghostty_id" 2>/dev/null
  fi
else
  move Zen 3
  move Zed 4
  move Ghostty 5
fi
