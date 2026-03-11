#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$DOTFILES_DIR/shared/ghostty/build.sh"
