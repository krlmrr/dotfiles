# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# User scripts override the packaged omarchy/binaries (custom screensaver, etc.)
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$PATH" ;;
esac
export PATH

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'
alias a='php artisan'
export PATH="$HOME/.config/composer/vendor/bin:$PATH"

# Added by LM Studio CLI (lms)
[ -d "$HOME/.lmstudio/bin" ] && export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section

[ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
export PATH="$HOME/.config/composer/vendor/bin:$PATH"

# Flock (added by `flock install`)
if [ -d "/home/karlm/.local/share/flock/bin" ]; then export PATH="/home/karlm/.local/share/flock/bin":"/home/karlm/.local/share/flock/node-global/current/bin":"$PATH"; fi
