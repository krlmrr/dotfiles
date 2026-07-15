echo "=== Mac Setup ==="

# Mac packages
echo "Installing Mac packages..."
# Homebrew refuses to load formulae from third-party taps until they're trusted.
# Tap + trust every non-official tap the Brewfile uses (including osx-cross/{arm,avr}
# pulled in transitively by qmk) before bundling, or the install aborts on a fresh Mac.
for t in qmk/qmk osx-cross/arm osx-cross/avr FelixKratz/formulae koekeishiya/formulae; do
  brew tap "$t"
  brew trust "$t"
done
brew bundle --file="$DOTFILES_DIR/mac/Brewfile"

# Caps Lock → Control (at boot via LaunchDaemon, Hammerspoon adds tap-for-Escape)
sudo cp "$DOTFILES_DIR/mac/CapsLockToControl.plist" /Library/LaunchDaemons/com.dotfiles.CapsLockToControl.plist
sudo chown root:wheel /Library/LaunchDaemons/com.dotfiles.CapsLockToControl.plist
sudo chmod 644 /Library/LaunchDaemons/com.dotfiles.CapsLockToControl.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.dotfiles.CapsLockToControl.plist 2>/dev/null || true

# Hammerspoon
link "$DOTFILES_DIR/mac/hammerspoon" ~/.hammerspoon

# VS Code
link "$DOTFILES_DIR/mac/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
link "$DOTFILES_DIR/mac/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"

# Sketchybar
link "$DOTFILES_DIR/mac/sketchybar" ~/.config/sketchybar

# menubar-toggle keepalive: launchd owns it so `sketchybar --reload` can't orphan
# it (sketchybarrc no longer launches it). Symlink the agent and (re)bootstrap.
link "$DOTFILES_DIR/mac/sketchybar/com.dotfiles.menubar-toggle.plist" ~/Library/LaunchAgents/com.dotfiles.menubar-toggle.plist
pkill -x menubar-toggle 2>/dev/null || true
launchctl bootout "gui/$(id -u)/com.dotfiles.menubar-toggle" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/com.dotfiles.menubar-toggle.plist 2>/dev/null || true

# yabai + skhd (tiling window manager)
link "$DOTFILES_DIR/mac/yabai/yabairc" ~/.yabairc
link "$DOTFILES_DIR/mac/yabai/skhdrc" ~/.skhdrc

# yabai sudoers: allow --load-sa / --uninstall-sa without password.
# yabai's default sudoers entry pins a sha256 of the binary, which breaks on
# every brew upgrade (SA stops loading, --sub-layer / space ops fail). Drop
# the hash so brewup can reload the scripting addition non-interactively.
echo 'karlm ALL = (root) NOPASSWD: /opt/homebrew/bin/yabai --load-sa, /opt/homebrew/bin/yabai --uninstall-sa' \
  | sudo tee /etc/sudoers.d/yabai >/dev/null
sudo chmod 440 /etc/sudoers.d/yabai
sudo visudo -c -f /etc/sudoers.d/yabai

# Start the window-manager stack. --restart-service reloads the freshly-symlinked
# config when the launchd agent is already installed; on a fresh Mac it isn't yet,
# so fall back to --start-service which installs and boots it.
yabai --restart-service 2>/dev/null || yabai --start-service
skhd --restart-service 2>/dev/null || skhd --start-service
brew services restart sketchybar

echo "=== Mac setup complete ==="
