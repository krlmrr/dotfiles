#!/bin/bash
# Mirror $SUDO_USER's COSMIC wallpaper config into the cosmic-greeter user's
# config so the login screen matches the user's current desktop background.
#
# cosmic-greeter runs as its own system user and can't read into a regular
# user's home directory. When a wallpaper outside /usr or /var is referenced,
# this helper copies the image into a greeter-readable location and rewrites
# the Path("...") references in the config files before installing them.
#
# Invoked by the cosmic-greeter-wallpaper-sync.service user unit via:
#   sudo -n /usr/local/sbin/cosmic-greeter-wallpaper-sync
set -euo pipefail

if [ -z "${SUDO_USER:-}" ]; then
    echo "Must be invoked via sudo from a user session" >&2
    exit 1
fi

USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
SRC="$USER_HOME/.config/cosmic/com.system76.CosmicBackground"
GREETER_HOME="/var/lib/cosmic-greeter"
DST="$GREETER_HOME/.config/cosmic/com.system76.CosmicBackground"
BG_DIR="$GREETER_HOME/.local/share/backgrounds"

[ -d "$SRC" ] || exit 0
id cosmic-greeter &>/dev/null || exit 0

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp -a "$SRC/." "$TMP/"

mkdir -p "$BG_DIR"

while IFS= read -r f; do
    while IFS= read -r path; do
        case "$path" in
            /usr/*|/var/*) continue ;;
        esac
        [ -f "$path" ] || continue
        base="$(basename "$path")"
        cp -f "$path" "$BG_DIR/$base"
        content="$(cat "$f")"
        printf '%s' "${content//Path(\"$path\")/Path(\"$BG_DIR/$base\")}" > "$f"
    done < <(grep -oE 'Path\("[^"]+"\)' "$f" | sed -E 's/^Path\("(.*)"\)$/\1/')
done < <(find "$TMP" -type f)

# cosmic-greeter clears per-output entries when `same-on-all: true` and then
# applies the `all` fallback to only one output, leaving the others on a stock
# default. Force `same-on-all: false` and write explicit per-output entries for
# each connected DRM connector so the greeter renders the configured wallpaper
# on every monitor.
if [ -f "$TMP/v1/same-on-all" ] && [ "$(cat "$TMP/v1/same-on-all")" = "true" ] && [ -f "$TMP/v1/all" ]; then
    for status in /sys/class/drm/card*-*/status; do
        [ -f "$status" ] || continue
        [ "$(cat "$status")" = "connected" ] || continue
        name="$(basename "$(dirname "$status")" | sed -E 's/^card[0-9]+-//')"
        [ "$name" = "all" ] && continue
        sed -E 's/output: "all"/output: "'"$name"'"/' "$TMP/v1/all" > "$TMP/v1/$name"
    done
    printf 'false' > "$TMP/v1/same-on-all"
fi

mkdir -p "$(dirname "$DST")"
rm -rf "$DST"
cp -a "$TMP/." "$DST/"

chown -R cosmic-greeter:cosmic-greeter "$GREETER_HOME/.config" "$BG_DIR"
find "$BG_DIR" -type f -exec chmod 644 {} +
find "$DST" -type f -exec chmod 644 {} +
