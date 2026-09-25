# Editor
unalias nv 2>/dev/null
nvim() { if [ $# -eq 0 ]; then command nvim .; else command nvim "$@"; fi; }
nv() { clear && nvim "$@"; }
alias nz="nv ~/.zshrc"
alias vim="nvim"
alias sourcez="source ~/.zshrc"

# Tools
alias lzg="lazygit"
alias yeet="sudo rm -rf"
alias mkd="mkdir -p"

# Jujutsu
alias lzj="lazyjj"
alias js="jj status"
alias jl="jj log"
alias jd="jj diff"
alias jn="jj new"

# Nvim restart helper
nvr() { cd "$1" && clear && nvim "${2:-}"; }

# Laravel
alias solo="a solo"
alias pail="a pail"

# Laravel Vendor
alias dust="./vendor/bin/duster fix"
alias duster="./vendor/bin/duster"
alias pint="./vendor/bin/pint"
alias stan="./vendor/bin/phpstan analyse"
alias pest="./vendor/bin/pest"

# Laravel Test
alias test="clear && a test"
alias tp="clear && a test -p"
alias tf="clear && a test --filter"

# Laravel Migrations
alias pam="a migrate"
alias pamf="a migrate:fresh"
alias pamfs="a migrate:fresh --seed"

# Filament
alias fu="a make:filament-user"
alias frg="a make:filament-resource --generate"
alias res="a make:filament-resource"
alias fp="a make:filament-page"
alias frm="a make:filament-relation-manager"

# NPM
alias watch="npm run watch"
alias prod="npm run production"
alias dev="npm run dev"
alias build="npm run build"

# Python
alias python="python3"
alias pip="pip3"

# Apps
alias code.="code ."
alias zed.="zed ."

publish() {
    local repo_name visibility="--private"

    # `publish --public` flips visibility; default is private.
    [[ "$1" == "--public" ]] && visibility="--public"

    repo_name=$(basename "$PWD")

    # Ensure we have a git repo with at least one commit on the main branch.
    [ -d .git ] || git init -b main -q
    git rev-parse HEAD &>/dev/null || { git add -A && git commit -qm "Initial commit"; }
    git branch -M main 2>/dev/null

    gh repo create "krlmrr/$repo_name" "$visibility" --source=. --remote=origin --push
}

# Prune merged branches, update the default branch, optionally start a new one.
# gsync              -> fetch, switch to default branch, fast-forward, prune merged locals
# gsync feat/thing   -> ...then cut a fresh branch off origin's default branch
gsync() {
    git rev-parse --is-inside-work-tree &>/dev/null || { echo "Not a git repository."; return 1; }

    git fetch --prune

    # Default branch from origin/HEAD, falling back to main.
    local default_branch
    default_branch=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
    default_branch="${default_branch:-main}"

    git checkout "$default_branch" && git merge --ff-only "origin/$default_branch"

    # Delete only local branches whose upstream was deleted after merge ([gone]).
    git for-each-ref --format '%(refname:short) %(upstream:track)' refs/heads \
        | awk '$2 == "[gone]" { print $1 }' \
        | while read -r branch; do git branch -D "$branch"; done

    [ -n "$1" ] && git checkout -b "$1" "origin/$default_branch"
}

# Herd
[ -d "$HOME/Library/Application Support/Herd/bin" ] && export PATH="$HOME/Library/Application Support/Herd/bin:$PATH"

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

brewup() {
  # Save versions up front so we can tell what was actually upgraded
  local before after herdr_before herdr_after
  before=$(brew info --json yabai 2>/dev/null | jq -r '.[0].installed[0].version' 2>/dev/null)
  herdr_before=$(brew info --json herdr 2>/dev/null | jq -r '.[0].installed[0].version' 2>/dev/null)

  brew update || return $?
  brew upgrade || return $?
  brew upgrade --greedy-auto-updates
  brew cleanup --prune=all

  after=$(brew info --json yabai 2>/dev/null | jq -r '.[0].installed[0].version' 2>/dev/null)
  herdr_after=$(brew info --json herdr 2>/dev/null | jq -r '.[0].installed[0].version' 2>/dev/null)

  if [[ "$before" != "$after" && -n "$after" ]]; then
    echo "yabai upgraded ($before → $after) — reloading SA, restarting, cleaning TCC"
    env -u TERMINFO sudo yabai --uninstall-sa
    env -u TERMINFO sudo yabai --load-sa
    yabai --restart-service
    sudo bash "${DOTFILES:-$HOME/dotfiles}/scripts/tcc-cleanup.sh"
  fi

  # `brew upgrade --greedy-auto-updates` is exactly what puts the Adobe/Google background
  # agents back — their installers re-register them on every version bump — and
  # a `brew upgrade` that retires a formula leaves its brew-services plist
  # behind as an orphan. So re-prune after every upgrade run, not just on setup.
  #
  # NOT `sudo bash` (unlike tcc-cleanup.sh above): this one must run as you, so
  # it can reach the gui/$UID domain for the per-user agents. It calls sudo
  # itself for the /Library ones and will prompt if the session has gone stale.
  bash "${DOTFILES:-$HOME/dotfiles}/scripts/prune-login-items.sh" --quiet

  # claude/skills/herdr/SKILL.md is a snapshot of `herdr --skill`, which prints
  # from the binary — so it goes stale silently on upgrade (202 -> 214 lines
  # between 0.9.0 and 0.9.1). Rewrite it here and let git surface the diff.
  # Reads the binary, not the running server, so it is correct before any restart.
  if [[ "$herdr_before" != "$herdr_after" && -n "$herdr_after" ]]; then
    echo "herdr upgraded ($herdr_before → $herdr_after) — refreshing the Claude skill"
    herdr --skill > ~/.claude/skills/herdr/SKILL.md
  fi
}

