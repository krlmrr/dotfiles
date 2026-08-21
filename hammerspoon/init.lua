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
-- ctrl+shift+N moves the focused window to desktop N and follows it there.
--
-- Hammerspoon must own these chords EXCLUSIVELY. skhd's event tap consumes the
-- chord before hs.hotkey sees it, so while skhdrc also bound ctrl+shift+N the
-- handler below simply never ran — which is why this looked like "the follow
-- doesn't work" through several rewrites when the follow code was fine all
-- along. The skhdrc binds are commented out; they must stay that way.
--
-- Cost of exclusivity: if Hammerspoon is down, these chords do nothing at all
-- (skhd is no longer a fallback). Uncomment the skhdrc block for move-only.
--
-- NO TIMERS. An earlier version polled for shift-release before posting, which
-- queued a keystroke to fire at an indeterminate later moment and produced
-- stray space switches that broke plain ctrl+N. Everything here is synchronous.
--
-- The follow posts macOS's own "Switch to Desktop N" shortcut (symbolichotkeys
-- 118-126 = ctrl+1..9). setFlags is the crux: the chord's own ctrl+shift is
-- still physically held when this runs, and without forcing the flags the
-- posted event merges with the real modifier state into ctrl+shift+N, which
-- matches nothing. Forcing ctrl-only defeated a synthetic held shift in
-- testing.
--
-- The window id comes from hs.window.focusedWindow(), not yabai: run from
-- Hammerspoon, `yabai -m window --space N` with no id exits 0 having done
-- nothing, because yabai reports no focused window in that context.
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
