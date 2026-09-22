export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#757575'
ZSH_AUTOSUGGEST_HISTORY_IGNORE="nvr *"

plugins=(
    git
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

export SUDO_ASKPASS="$DOTFILES/scripts/askpass.sh"

[ -d "$HOME/.lmstudio/bin" ] && export PATH="$PATH:$HOME/.lmstudio/bin"

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

source "$XDG_CONFIG_HOME/zsh/aliases.sh"

