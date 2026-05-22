# Herd
export PATH="$HOME/Library/Application Support/Herd/bin:$PATH"

alias a="php artisan"

alias brewup="brew upgrade && brew upgrade --greedy && brew cleanup --prune=all && env -u TERMINFO sudo yabai --uninstall-sa && env -u TERMINFO sudo yabai --load-sa && yabai --restart-service && sudo bash ~/Code/dotfiles/mac/tcc-cleanup.sh && open /Applications/Raycast.app/"

