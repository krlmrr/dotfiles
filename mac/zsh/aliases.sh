# Herd
export PATH="$HOME/Library/Application Support/Herd/bin:$PATH"

alias a="php artisan"

# Clear any pre-existing brewup alias (from older builds of this file or sourced state)
# so the function definition below doesn't collide with a stale alias in re-sourced shells.
unalias brewup 2>/dev/null

brewup() {
  # Save yabai version so we can tell if it was actually upgraded
  local before after
  before=$(brew info --json yabai 2>/dev/null | jq -r '.[0].installed[0].version' 2>/dev/null)

  brew upgrade || return $?
  brew upgrade --greedy
  brew cleanup --prune=all

  after=$(brew info --json yabai 2>/dev/null | jq -r '.[0].installed[0].version' 2>/dev/null)

  if [[ "$before" != "$after" && -n "$after" ]]; then
    echo "yabai upgraded ($before → $after) — reloading SA, safe-restarting"
    env -u TERMINFO sudo yabai --uninstall-sa
    env -u TERMINFO sudo yabai --load-sa
    # retile.sh handles position save/restore around --restart-service
    "$HOME/Code/dotfiles/mac/yabai/retile.sh"
  else
    echo "yabai not upgraded — skipping SA reload and service restart"
  fi

  sudo bash ~/Code/dotfiles/mac/tcc-cleanup.sh
  open /Applications/Raycast.app/
}

