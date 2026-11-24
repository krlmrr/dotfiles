export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#757575'
ZSH_AUTOSUGGEST_HISTORY_IGNORE="nvr *"

plugins=(
    git
    herdr
    zsh-autosuggestions
    zsh-syntax-highlighting
)

fpath=("$HOME/.local/share/zsh/site-functions" $fpath)

source $ZSH/oh-my-zsh.sh

setopt HIST_IGNORE_SPACE

export HOMEBREW_NO_ENV_HINTS=1

export PATH="$HOME/.local/bin:$PATH:$HOME/.composer/vendor/bin:$HOME/.config/composer/vendor/bin"

export DOTFILES="$HOME/dotfiles"
export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR="nvim"
export TODO_FILE="$HOME/todo.txt"

export SUDO_ASKPASS="$DOTFILES/scripts/askpass.sh"

[ -d "$HOME/.lmstudio/bin" ] && export PATH="$PATH:$HOME/.lmstudio/bin"
[ -d "$HOME/.cargo/bin" ] && export PATH="$PATH:$HOME/.cargo/bin"

source <(fzf --zsh)

y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

if [ -d "$HOME/Library/Application Support/Herd" ]; then
    for php_version in 74 83 84 85 86; do
        export "HERD_PHP_${php_version}_INI_SCAN_DIR=$HOME/Library/Application Support/Herd/config/php/$php_version"
    done

    export NVM_DIR="$HOME/Library/Application Support/Herd/config/nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
fi

[ -f "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh" ] \
    && builtin source "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh"

# Editor
unalias nv 2>/dev/null
nvim() { if [ $# -eq 0 ]; then command nvim .; else command nvim "$@"; fi; }
nv() { clear && nvim "$@"; }
lvim() { NVIM_APPNAME=lvim nvim "$@"; }
notes() {
  [ -d "$HOME/notes" ] || gh repo clone krlmrr/notes "$HOME/notes" || return
  (
    cd "$HOME/notes" || exit
    git pull --rebase --autostash --quiet || echo "Couldn't pull notes, using the local copy."
    [ "$1" = "sync" ] || glow "$@"
    git add -A
    git diff --cached --quiet || git commit --quiet -m "Update notes from $(hostname -s)"
    git push --quiet || echo "Couldn't push notes, they'll go up next time."
    [ "$1" = "sync" ] && echo "Notes synced."
  )
}
alias nz="nv ~/.zshrc"
alias vim="nvim"
alias sourcez="source ~/.zshrc"

# Tools
alias lzg="lazygit"
alias yeet="sudo rm -rf"
alias mkd="mkdir -p"

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
# herdr check uses returns nothing for them.
_cask_version() {
  brew info --json=v2 --cask "$1" 2>/dev/null \
    | jq -r '.casks[0].installed // empty' 2>/dev/null
}

brewup() {
  # Save versions up front so we can tell what was actually upgraded
  local herdr_before herdr_after
  herdr_before=$(brew info --json herdr 2>/dev/null | jq -r '.[0].installed[0].version' 2>/dev/null)

  brew update || return $?
  brew upgrade || return $?
  brew upgrade --greedy-auto-updates
  brew cleanup --prune=all

  herdr_after=$(brew info --json herdr 2>/dev/null | jq -r '.[0].installed[0].version' 2>/dev/null)

  # `brew upgrade --greedy-auto-updates` is exactly what puts the Adobe/Google background
  # agents back — their installers re-register them on every version bump — and
  # a `brew upgrade` that retires a formula leaves its brew-services plist
  # behind as an orphan. So re-prune after every upgrade run, not just on setup.
  #
  # NOT `sudo bash`: this one must run as you, so
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


# Keep the Brewfile in step with brew: `brew install` adds the line in sorted
# order within its section, `brew uninstall` removes it. Commit the diff when ready.
if [[ "$OSTYPE" == darwin* ]]; then
  BREWFILE="$DOTFILES/homebrew/.config/homebrew/Brewfile"

  _brewfile_line() {
    local short="${2##*/}"
    printf '^%s "([^"]*/)?%s"' "$1" "$(printf '%s' "$short" | sed 's/[.+]/\\&/g')"
  }

  _brewfile_add() {
    local kind="$1" name="$2"
    grep -qE "$(_brewfile_line "$kind" "$name")" "$BREWFILE" && return
    awk -v kind="$kind" -v name="$name" '
      { lines[NR] = $0 }
      $1 == kind {
        entry = $2; gsub(/"/, "", entry)
        if (!first) first = NR
        if (entry < name) after = NR
      }
      END {
        at = after ? after : (first ? first - 1 : NR)
        if (at == 0) printf "%s \"%s\"\n", kind, name
        for (i = 1; i <= NR; i++) {
          print lines[i]
          if (i == at) printf "%s \"%s\"\n", kind, name
        }
      }' "$BREWFILE" > "$BREWFILE.tmp" && mv "$BREWFILE.tmp" "$BREWFILE"
    echo "Brewfile: added $kind \"$name\""
  }

  _brewfile_remove() {
    local re="$(_brewfile_line '(brew|cask)' "$1")"
    grep -qE "$re" "$BREWFILE" || return
    grep -vE "$re" "$BREWFILE" > "$BREWFILE.tmp" && mv "$BREWFILE.tmp" "$BREWFILE"
    echo "Brewfile: removed ${1##*/}"
  }

  brew() {
    command brew "$@" || return
    [[ -f "$BREWFILE" ]] || return 0
    local verb="$1" arg cask=0
    shift
    [[ " $* " == *" --cask "* || " $* " == *" --casks "* ]] && cask=1
    for arg in "$@"; do
      [[ "$arg" == -* ]] && continue
      case "$verb" in
        install)
          if (( cask )) || command brew list --cask "${arg##*/}" &>/dev/null; then
            _brewfile_add cask "$arg"
          else
            _brewfile_add brew "$arg"
          fi ;;
        uninstall|remove|rm) _brewfile_remove "$arg" ;;
      esac
    done
  }
fi



# Herd injected PHP 8.4 configuration.
export HERD_PHP_84_INI_SCAN_DIR="/Users/karlm/Library/Application Support/Herd/config/php/84"


# Herd injected PHP 8.6 configuration.
export HERD_PHP_86_INI_SCAN_DIR="/Users/karlm/Library/Application Support/Herd/config/php/86"


# Herd injected PHP 8.5 configuration.
export HERD_PHP_85_INI_SCAN_DIR="/Users/karlm/Library/Application Support/Herd/config/php/85"


# Herd injected PHP 8.3 configuration.
export HERD_PHP_83_INI_SCAN_DIR="/Users/karlm/Library/Application Support/Herd/config/php/83"


# Herd injected PHP 7.4 configuration.
export HERD_PHP_74_INI_SCAN_DIR="/Users/karlm/Library/Application Support/Herd/config/php/74"


# Herd injected PHP 8.2 configuration.
export HERD_PHP_82_INI_SCAN_DIR="/Users/karlm/Library/Application Support/Herd/config/php/82"

# Flock (added by `flock install`)
if [ -d "/home/karlm/.local/share/flock/bin" ]; then export PATH="/home/karlm/.local/share/flock/bin":"/home/karlm/.local/share/flock/node-global/current/bin":"$PATH"; fi
