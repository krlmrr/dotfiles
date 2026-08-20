# Herd
export PATH="$HOME/Library/Application Support/Herd/bin:$PATH"

alias a="php artisan"

# Clear any pre-existing brewup alias (from older builds of this file or sourced state)
# so the function definition below doesn't collide with a stale alias in re-sourced shells.
unalias brewup 2>/dev/null

# Installed version of a cask. Casks need --json=v2 --cask; the v1 form the
# yabai check uses returns nothing for them.
_cask_version() {
  brew info --json=v2 --cask "$1" 2>/dev/null \
    | jq -r '.casks[0].installed // empty' 2>/dev/null
}

_frontmost_app() {
  osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null
}

# Raise an app by process name. Name is passed as an argv item rather than
# interpolated into the script text, so a name with quotes can't break it.
_focus_app() {
  [[ -n "$1" ]] || return 0
  osascript - "$1" <<'OSA' 2>/dev/null
on run argv
  tell application "System Events"
    set frontmost of (first process whose name is (item 1 of argv)) to true
  end tell
end run
OSA
}

brewup() {
  # Save versions up front so we can tell what was actually upgraded
  local before after ray_before ray_after front
  before=$(brew info --json yabai 2>/dev/null | jq -r '.[0].installed[0].version' 2>/dev/null)
  ray_before=$(_cask_version ray)
  # Remember what had focus. Cask installers steal it, and a relaunched Raycast
  # can pop its own window that `open -gj` cannot suppress, so restore focus at
  # the end rather than hoping nothing grabs it.
  front=$(_frontmost_app)

  brew upgrade || return $?
  brew upgrade --greedy
  brew cleanup --prune=all

  after=$(brew info --json yabai 2>/dev/null | jq -r '.[0].installed[0].version' 2>/dev/null)
  ray_after=$(_cask_version ray)

  if [[ "$before" != "$after" && -n "$after" ]]; then
    echo "yabai upgraded ($before → $after) — reloading SA, restarting, cleaning TCC"
    env -u TERMINFO sudo yabai --uninstall-sa
    env -u TERMINFO sudo yabai --load-sa
    yabai --restart-service
    sudo bash ~/Code/dotfiles/mac/tcc-cleanup.sh
  else
    echo "yabai not upgraded — skipping SA reload, restart, and TCC cleanup"
  fi

  # `brew upgrade --greedy` is exactly what puts the Adobe/Google background
  # agents back — their installers re-register them on every version bump — and
  # a `brew upgrade` that retires a formula leaves its brew-services plist
  # behind as an orphan. So re-prune after every upgrade run, not just on setup.
  #
  # NOT `sudo bash` (unlike tcc-cleanup.sh above): this one must run as you, so
  # it can reach the gui/$UID domain for the per-user agents. It calls sudo
  # itself for the /Library ones and will prompt if the session has gone stale.
  bash ~/Code/dotfiles/mac/prune-login-items.sh

  # Only relaunch Raycast if it was actually replaced — upgrading the cask quits
  # the running app, so it needs reopening; otherwise leave it alone rather than
  # yanking focus on every brewup.
  #
  # Resolve by app name, not path: Raycast left beta on 2026-08-20 and the bundle
  # moved from "Raycast Beta.app" to "Raycast.app", breaking the old hardcoded
  # path. `open -a` survives that kind of rename.
  if [[ "$ray_before" != "$ray_after" && -n "$ray_after" ]]; then
    echo "Raycast upgraded ($ray_before → $ray_after) — relaunching"
    # -g: don't bring to the foreground, -j: launch hidden. Raycast is an
    # LSUIElement app (menu-bar only, no Dock icon), so this just gets the
    # hotkey listener back without stealing focus or popping the search window.
    open -gj -a Raycast
  else
    echo "Raycast not upgraded — leaving it as-is"
  fi

  # Put focus back where it started, if anything moved it.
  if [[ -n "$front" && "$(_frontmost_app)" != "$front" ]]; then
    echo "restoring focus to $front"
    _focus_app "$front"
  fi
}

