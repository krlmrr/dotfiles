# Editor
unalias nv 2>/dev/null
nv() { clear && nvim "${1:-.}"; }
alias nz="nv ~/.zshrc"
alias vim="nvim"
alias sourcez="source ~/.zshrc"

# Tools
alias lz="lazygit"
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
alias ps.="phpstorm ."
alias zed.="zed ."
