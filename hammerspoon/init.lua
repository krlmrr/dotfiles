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
-- cannot focus a space — `space --focus` needs the scripting addition SIP
-- blocks — so hs.spaces drives the switch.
--
-- Four mechanisms were tried before this one; all of them posted macOS's own
-- ctrl+N shortcut and all of them failed, each for a different reason:
--   1. hs.eventtap.keyStroke — appeared to be a no-op (it is not; see 3).
--   2. Held modifiers: the chord's own ctrl+shift is still down when the handler
--      runs, so the posted ctrl+N merged into ctrl+shift+N and matched nothing.
--      Forcing the event flags fixed that.
--   3. skhd's event tap consumed the chord before hs.hotkey ever saw it, so
--      while skhdrc also bound these the handler never ran at all.
--   4. Fatally: the frontmost app eats ctrl+1..9 if it binds them. VS Code does
--      by default (Focus Nth Editor Group), and the key is necessarily posted
--      while the window you just moved is still frontmost. Confirmed — with VS
--      Code frontmost the post is swallowed, with Finder frontmost it works.
--
-- hs.spaces.gotoSpace posts no keys, so nothing can intercept it and no modifier
-- state matters. Cost: it drives the Mission Control interface, so each switch
-- flashes it. That is the accepted trade for actually working every time.
--
-- Space indices: yabai's mission-control index spans all displays, so flatten
-- each screen's list in screen order to match. Correct on one display; suspect
-- this first if a follow lands on the wrong space multi-display.
local YABAI = "/opt/homebrew/bin/yabai"

local function flatSpaces()
    local flat = {}
    for _, scr in ipairs(hs.screen.allScreens()) do
        for _, id in ipairs(hs.spaces.spacesForScreen(scr:getUUID()) or {}) do
            table.insert(flat, id)
        end
    end
    return flat
end

-- target is 1-9, or "prev"/"next". Move first, then ask yabai where the window
-- landed — one code path for both, and no end-of-range arithmetic to get wrong.
local function moveAndFollow(target)
    return function()
        pcall(function()
            local win = hs.window.focusedWindow()
            if not win then return end
            local _, ok = hs.execute(string.format(
                "%s -m window %d --space %s", YABAI, win:id(), tostring(target)), true)
            if not ok then
                hs.alert.show("No space " .. tostring(target), 0.7)
                return
            end
            local out = hs.execute(string.format("%s -m query --windows --window %d", YABAI, win:id()), true)
            local info = out and hs.json.decode(out)
            local flat = flatSpaces()
            if info and info.space and flat[info.space] then
                hs.spaces.gotoSpace(flat[info.space])
            end
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
