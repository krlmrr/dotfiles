# Editor
unalias nv 2>/dev/null
nv() { clear && nvim "${1:-.}"; }
alias nz="nv ~/.zshrc"
alias vim="nvim"
alias sourcez="~/Code/dotfiles/buildzshrc && source ~/.zshrc"

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
