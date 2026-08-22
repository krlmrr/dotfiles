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
-- ctrl+shift+1..9 / ctrl+shift+arrows: move the focused window to that desktop
-- and go there too. yabai does the move (public API, fine with SIP on) but
-- cannot focus a space — `space --focus` needs the scripting addition SIP blocks
-- — so we post macOS's own "Switch to Desktop N" shortcut and let Apple do the
-- switching with its native animation.
--
-- setFlags is the load-bearing part. The chord's own ctrl+shift is still
-- physically held when this runs, and without forcing the flags the posted event
-- merges with the real modifier state into ctrl+shift+N, which matches no
-- shortcut — the window moves and the view never follows.
--
-- Hammerspoon must own these chords EXCLUSIVELY: skhd's event tap consumes the
-- chord before hs.hotkey ever sees it, so binding them in skhdrc too silently
-- disables this. They are commented out there; keep it that way.
--
-- Rejected alternatives, for anyone tempted:
--   hs.spaces.gotoSpace — works and cannot be intercepted, but drives the
--     Mission Control interface so every switch flashes it. Tried; disliked.
--   osascript posting the key — cannot force event flags, so it loses to the
--     held ctrl+shift.
--   A skhd bind plus a CGEventSetFlags helper binary (yabai/helpers/
--     space-follow.swift, still in the repo, unused) — worked, then stopped
--     following for reasons never pinned down. Hammerspoon is where this has
--     been reliable.
--
-- NO TIMERS here on purpose: an earlier version polled for shift-release and
-- queued keystrokes that fired later, which produced stray space switches and
-- broke plain ctrl+N.
local YABAI = "/opt/homebrew/bin/yabai"
local KEYCODE = { [1]=18, [2]=19, [3]=20, [4]=21, [5]=23, [6]=22, [7]=26, [8]=28, [9]=25 }
local ARROW = { prev = 123, next = 124 } -- ctrl+left / ctrl+right = move a space

local function post(kc)
    local down = hs.eventtap.event.newKeyEvent(kc, true)
    down:setFlags({ ctrl = true }); down:post()
    local up = hs.eventtap.event.newKeyEvent(kc, false)
    up:setFlags({ ctrl = true }); up:post()
end

-- target is 1-9, or "prev"/"next" for the adjacent desktop.
local function moveAndFollow(target)
    return function()
        pcall(function()
            local win = hs.window.focusedWindow()
            if not win then return end
            hs.execute(string.format("%s -m window %d --space %s", YABAI, win:id(), tostring(target)), true)
            local kc = KEYCODE[target] or ARROW[target]
            if not kc then return end
            post(kc)
        end)
    end
end

local moveFollowKeys = {}
pcall(function()
    for i = 1, 9 do
        table.insert(moveFollowKeys,
            hs.hotkey.bind({ "ctrl", "shift" }, tostring(i), moveAndFollow(i)))
    end
    table.insert(moveFollowKeys, hs.hotkey.bind({ "ctrl", "shift" }, "left",  moveAndFollow("prev")))
    table.insert(moveFollowKeys, hs.hotkey.bind({ "ctrl", "shift" }, "right", moveAndFollow("next")))
end)

-- ── Auto-reload this config when it changes ─────────────────────────────────
-- Saves a trip to the menu bar on every edit. Only reacts to .lua files, since
-- the watcher fires for anything in the directory.
--
-- Kept in a file-scope local on purpose: a pathwatcher that isn't referenced
-- gets garbage-collected and silently stops working. Same reason the eventtaps
-- and watchers above are held in locals.
--
-- Caveat: a reload on a file with a syntax error leaves NOTHING loaded, which
-- takes the Caps Lock handling down with it until the error is fixed. Check the
-- console if the keyboard suddenly feels wrong after an edit.
local configWatcher = hs.pathwatcher.new(
    os.getenv("HOME") .. "/Code/dotfiles/hammerspoon/",
    function(files)
        for _, f in ipairs(files) do
            if f:sub(-4) == ".lua" then
                hs.reload()
                return
            end
        end
    end
):start()
