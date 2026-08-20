#!/usr/bin/env bash
#
# Remove Adobe and Google background agents (System Settings > General >
# Login Items & Extensions > App Background Activity).
#
# Deleting the plist alone is not enough: both vendors reinstall their agents on
# the next app update, and toggling them off in System Settings does not survive
# that either. So for every job we also `launchctl disable`, which writes a
# persistent override keyed by *service name* — it outlives the plist, so a
# reinstalled agent stays dead until explicitly re-enabled.
#
# Phase 2 sweeps *orphans* of any vendor: plists whose target binary no longer
# exists. `brew uninstall <x>` does not run `brew services stop` first, so the
# agent outlives the formula (ollama, openvpn). macOS still parses the leftover
# plist, can't resolve it to a signed bundle, and shows it as a blank-icon
# "Item from unidentified developer" row you can't get rid of from the UI.
#
# Idempotent and safe to re-run; that's the point. Run it again after any Adobe
# or Chrome update, or after uninstalling a brew service.
#
# Usage:
#   bash mac/prune-login-items.sh              # prune
#   bash mac/prune-login-items.sh --dry-run    # show what would be pruned
#
# To undo, re-enable a service and let the app reinstall its agent:
#   launchctl enable gui/$(id -u)/com.adobe.ccxprocess
#   sudo launchctl enable system/com.adobe.acc.installer.v2

shopt -s nullglob

DRY_RUN=0
[[ "$1" == "--dry-run" || "$1" == "-n" ]] && DRY_RUN=1

if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not with sudo — it needs your GUI" >&2
    echo "domain (gui/$(id -u)) to disable per-user agents, and calls sudo" >&2
    echo "itself for the system ones." >&2
    exit 1
fi

UID_NUM="$(id -u)"

# Agents matching these prefixes get pruned from the launchd directories below.
PREFIXES=(com.adobe. com.google.)

# Never touch these, even on a prefix match. Google ships security tooling
# (santa) under the same namespace as its updaters — belt and braces in case
# this machine ever gets it.
KEEP=(com.google.santad com.google.santa.bundleservice com.google.santa.metricservice)

pruned=0
skipped=0
failed=0
# Plists already handled this run. Phase 2 re-walks the same directories, and a
# vendor agent can also be an orphan (Adobe CC currently is both), so without
# this the dry-run count double-reports it. Newline-delimited string rather than
# an associative array: macOS ships bash 3.2, which has no `declare -A`.
SEEN=$'\n'

is_kept() {
    local label="$1" k
    for k in "${KEEP[@]}"; do
        [[ "$label" == "$k" ]] && return 0
    done
    return 1
}

# prune <plist> <domain> <sudo|nosudo> <disable|nodisable>
prune() {
    local plist="$1" domain="$2" needs_sudo="$3" disable="${4:-disable}"
    local label
    case "$SEEN" in *$'\n'"$plist"$'\n'*) return ;; esac
    SEEN="$SEEN$plist"$'\n'
    # Prefer the plist's own Label; fall back to the filename for the empty
    # tombstone plists Google's Keystone-to-GoogleUpdater migration left behind.
    label="$(plutil -extract Label raw "$plist" 2>/dev/null)"
    if [[ -z "$label" ]]; then
        label="$(basename "$plist" .plist)"
    fi

    if is_kept "$label"; then
        echo "  keep    $label (allowlisted)"
        ((skipped++))
        return
    fi

    if (( DRY_RUN )); then
        echo "  would   $label  [$domain]  $plist"
        ((pruned++))
        return
    fi

    local SUDO=()
    [[ "$needs_sudo" == "sudo" ]] && SUDO=(sudo)

    # bootout stops it now; disable keeps it from coming back on reinstall.
    # Orphans get no `disable`: the override is keyed by label and would persist,
    # so disabling homebrew.mxcl.ollama would silently break a future
    # `brew services start ollama`. Deleting the dead plist is enough.
    "${SUDO[@]}" launchctl bootout "$domain/$label" 2>/dev/null || true
    if [[ "$disable" == "disable" ]]; then
        "${SUDO[@]}" launchctl disable "$domain/$label" 2>/dev/null || true
    fi
    "${SUDO[@]}" rm -f "$plist" 2>/dev/null

    # Report what happened, not what was attempted. Checking the file is the
    # only honest test: rm's exit status can be masked by sudo failing, and
    # claiming a prune that didn't happen is worse than no output at all.
    if [[ -e "$plist" ]]; then
        echo "  FAILED  $label — could not remove $plist" >&2
        ((failed++))
    else
        echo "  pruned  $label"
        ((pruned++))
    fi
}

scan() {
    local dir="$1" domain="$2" needs_sudo="$3" p prefix
    [[ -d "$dir" ]] || return 0
    echo "$dir"
    for prefix in "${PREFIXES[@]}"; do
        for p in "$dir/$prefix"*.plist; do
            [[ -e "$p" ]] || continue
            prune "$p" "$domain" "$needs_sudo"
        done
    done
}

# Resolve the executable a job points at. Jobs using BundleProgram (resolved
# relative to a containing bundle) are skipped rather than guessed at — a false
# positive here would delete a working agent.
job_program() {
    local plist="$1" prog
    prog="$(plutil -extract ProgramArguments.0 raw "$plist" 2>/dev/null)"
    [[ -z "$prog" ]] && prog="$(plutil -extract Program raw "$plist" 2>/dev/null)"
    echo "$prog"
}

scan_orphans() {
    local dir="$1" domain="$2" needs_sudo="$3" p prog
    [[ -d "$dir" ]] || return 0
    echo "$dir"
    for p in "$dir"/*.plist; do
        [[ -e "$p" ]] || continue
        prog="$(job_program "$p")"
        # No resolvable program key at all: inert, but not provably dead. Leave it.
        [[ -z "$prog" ]] && continue
        [[ -e "$prog" ]] && continue
        echo "  orphan  $(basename "$p" .plist) -> $prog"
        prune "$p" "$domain" "$needs_sudo" nodisable
    done
}

# Is there anything in /Library to prune? Only those need root, so checking
# first keeps the common already-clean case from prompting for a password —
# this runs from brewup on every upgrade, where a spurious prompt is noise.
system_work_pending() {
    local d p prefix prog
    for d in /Library/LaunchAgents /Library/LaunchDaemons; do
        [[ -d "$d" ]] || continue
        for prefix in "${PREFIXES[@]}"; do
            for p in "$d/$prefix"*.plist; do
                [[ -e "$p" ]] && return 0
            done
        done
        for p in "$d"/*.plist; do
            [[ -e "$p" ]] || continue
            prog="$(job_program "$p")"
            [[ -z "$prog" ]] && continue
            [[ -e "$prog" ]] || return 0
        done
    done
    return 1
}

# Establish sudo before touching anything. Without it we'd prune the per-user
# agents, fail on the rest, and leave the job half done — which is exactly what
# happened the first time this ran somewhere with no TTY for the prompt.
if (( ! DRY_RUN )) && system_work_pending; then
    if ! sudo -n true 2>/dev/null && ! sudo -v; then
        echo "Can't get sudo, and the /Library items need it. Nothing was changed." >&2
        echo "Run this from a real terminal (a non-interactive shell has no TTY for" >&2
        echo "the password prompt), or pre-authorize with 'sudo -v' first." >&2
        exit 1
    fi
fi

if (( DRY_RUN )); then
    echo "=== Pruning Adobe/Google login items (dry run) ==="
else
    echo "=== Pruning Adobe/Google login items ==="
fi

# Per-user agents. Root-owned /Library/LaunchAgents jobs still run in the
# user's GUI domain, so they're disabled there but need sudo to delete.
scan "$HOME/Library/LaunchAgents" "gui/$UID_NUM" nosudo
scan "/Library/LaunchAgents"      "gui/$UID_NUM" sudo
# System-wide daemons live in the system domain.
scan "/Library/LaunchDaemons"     "system"       sudo

echo
echo "--- Orphans (target binary no longer installed) ---"
scan_orphans "$HOME/Library/LaunchAgents" "gui/$UID_NUM" nosudo
scan_orphans "/Library/LaunchAgents"      "gui/$UID_NUM" sudo
scan_orphans "/Library/LaunchDaemons"     "system"       sudo

echo
if (( pruned == 0 && failed == 0 )); then
    echo "Nothing to prune — already clean."
else
    if (( DRY_RUN )); then
        echo "$pruned item(s) would be pruned; $skipped kept."
    else
        echo "Pruned $pruned item(s); $skipped kept; $failed failed."
        if (( failed )); then
            echo "Re-run to retry the failures." >&2
            exit 1
        fi
    fi
fi
