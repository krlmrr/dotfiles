#!/bin/sh
set -e

ZEN_DIR="$HOME/Library/Application Support/zen"
if [ -n "$1" ]; then
  PROFILE="$1"
else
  DEFAULT_PATH="$(awk -F= '/^\[Install/{found=1} found && $1=="Default"{print $2; exit}' "$ZEN_DIR/profiles.ini")"
  case "$DEFAULT_PATH" in
    /*) PROFILE="$DEFAULT_PATH" ;;
    *) PROFILE="$ZEN_DIR/$DEFAULT_PATH" ;;
  esac
  echo "Using profile: $PROFILE"
fi
RESOURCES="/Applications/Zen.app/Contents/Resources"
HERE="$(cd "$(dirname "$0")" && pwd)"

if pgrep -f "Zen.app/Contents/MacOS" >/dev/null; then
  echo "Quit Zen first (Cmd+Q)."
  exit 1
fi
[ -d "$PROFILE" ] || { echo "No such profile folder: $PROFILE"; exit 1; }

WORK="$(mktemp -d)"
git clone -q --depth 1 https://github.com/MrOtherGuy/fx-autoconfig.git "$WORK/fx-autoconfig"

sudo cp "$WORK/fx-autoconfig/program/config.js" "$RESOURCES/"
sudo mkdir -p "$RESOURCES/defaults/pref"
sudo cp "$WORK/fx-autoconfig/program/defaults/pref/config-prefs.js" "$RESOURCES/defaults/pref/"

mkdir -p "$PROFILE/chrome/JS"
rm -rf "$PROFILE/chrome/utils"
cp -R "$WORK/fx-autoconfig/profile/chrome/utils" "$PROFILE/chrome/"
cp "$HERE/space_extensions.sys.mjs" "$PROFILE/chrome/JS/"

rm -rf "$HOME/Library/Caches/zen/Profiles/$(basename "$PROFILE")/startupCache"
rm -rf "$WORK"

echo "Installed. Start Zen and switch Spaces to test."
