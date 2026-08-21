hs.allowAppleScript(true)

-- Caps Lock → tap for Escape, hold for Control
-- Requires: System Preferences > Keyboard > Modifier Keys > Caps Lock → Control

local log = hs.logger.new("capslock", "info")

local sendEscape = false
local lastModifiers = {}
-- If control is held longer than this, don't send escape
local cancelTimer = hs.timer.delayed.new(0.150, function()
    sendEscape = false
end)

-- Watch for control key state changes (flagsChanged)
local controlTap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(event)
    local newModifiers = event:getFlags()

    -- Ignore if control state hasn't changed
    if lastModifiers["ctrl"] == newModifiers["ctrl"] then
        return false
    end

    if not lastModifiers["ctrl"] then
        -- Control just pressed
        lastModifiers = newModifiers
        sendEscape = true
        cancelTimer:start()
    else
        -- Control just released
        if sendEscape then
            hs.eventtap.keyStroke({}, "escape", 1)
        end
        lastModifiers = newModifiers
        cancelTimer:stop()
    end

    return false
end)

-- Any other key pressed while control is held cancels the escape
local keyDownTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    sendEscape = false
    return false
end)

local function restartAll(reason)
    controlTap:stop()
    keyDownTap:stop()
    controlTap:start()
    keyDownTap:start()
    log.i("Restarted: " .. reason)
end

restartAll("init")

-- Restart eventtaps after sleep/wake, screen unlock, and USB changes
local watcher = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.systemDidWake then
        restartAll("systemDidWake")
    elseif event == hs.caffeinate.watcher.screensDidWake then
        restartAll("screensDidWake")
    elseif event == hs.caffeinate.watcher.screensDidUnlock then
        restartAll("screensDidUnlock")
    end
end)
watcher:start()

local usbWatcher = hs.usb.watcher.new(function(data)
    restartAll("USB change")
end)
usbWatcher:start()

local spaceWatcher = hs.spaces.watcher.new(function()
    restartAll("space change")
end)
spaceWatcher:start()

-- Alt+G: toggle yabai + skhd
hs.hotkey.bind({"alt"}, "g", function()
    local output = hs.execute("pgrep -x yabai 2>/dev/null", true) or ""
    if output:match("%d+") then
        hs.execute("yabai --stop-service &", true)
        hs.execute("skhd --stop-service &", true)
        hs.execute("/Users/karlm/Code/dotfiles/yabai/show-dock.sh &", true)
        hs.alert.show("Tiling off")
    else
        hs.execute("/Users/karlm/Code/dotfiles/yabai/hide-dock.sh &", true)
        hs.execute("yabai --start-service &", true)
        hs.execute("skhd --start-service &", true)
        hs.alert.show("Tiling on")
    end
end)

-- Periodic health check: restart eventtaps if anything has silently died
local healthCheck = hs.timer.new(30, function()
    if not controlTap:isEnabled() or not keyDownTap:isEnabled() then
        restartAll("health check")
    end
end)
healthCheck:start()
-- ── Remote control / inspection ─────────────────────────────────────────────
-- Loads the message port the `hs` CLI talks to, so this config can be reloaded
-- and inspected from a terminal (`hs -c 'hs.reload()'`, `hs -c '...'`) instead
-- of only from the menu bar. Useful precisely when Hammerspoon is misbehaving.
pcall(function() require("hs.ipc") end)

-- ── Move window to a space AND follow it ────────────────────────────────────
-- REMOVED 2026-08-21, pending a rethink. See git history for the attempts.
--
-- The goal: ctrl+shift+N moves the focused window to desktop N and takes you
-- with it. yabai can do the move (public API, works with SIP on) but not the
-- follow (`space --focus` needs the blocked scripting addition).
--
-- What was tried, and why each failed:
--   hs.eventtap.keyStroke posting ctrl+N — no-op; synthetic events do not
--     trigger macOS symbolichotkeys at all.
--   hs.spaces.gotoSpace — works for any index, but drives the Mission Control
--     interface, so every switch flashes it. Not native-feeling.
--   osascript + System Events posting ctrl+N — works when fired from a script
--     with no modifiers held, but NOT from the hotkey: while ctrl+shift is
--     physically down the synthetic ctrl+N merges with the real modifier state,
--     macOS sees ctrl+shift+N, and nothing matches. Confirmed directly.
--   Polling for shift release before posting — this is where it went wrong.
--     Every press spawns a poll chain that fires a keystroke at an
--     indeterminate later moment, which produced stray space switches and made
--     plain ctrl+N appear broken.
--
-- Anything further needs a mechanism that does not synthesize keystrokes and
-- does not go through Mission Control. Unresolved.
