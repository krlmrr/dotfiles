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
-- Arrow keycodes are deliberately NOT posted. macOS's "Move left/right a space"
-- (symbolichotkeys 79/81) ignores synthetic events -- it only responds to real
-- hardware keys -- so posting ctrl+arrow, with or without the Fn flag those
-- shortcuts are registered with (mask 0x840000), moves nothing and the view
-- stays put while the window leaves. "Switch to Desktop N" (118-126, plain ctrl,
-- mask 0x40000) DOES accept a posted event. So prev/next resolve to an absolute
-- space index and reuse the digit path, which is the only mechanism that works.
--
-- macOS only has "Switch to Desktop N" shortcuts for 1-9, so past desktop 9 --
-- which is where a second display's spaces land, since yabai indexes globally --
-- there is no chord to post and the view used to stay behind. Those cases fall
-- back to focusing the window instead: activating a window pulls the view to its
-- space, which needs no shortcut and is not limited to 9. That relies on
-- AppleSpacesSwitchOnActivate, which is on unless deliberately turned off.
--
-- The post is still preferred where a chord exists: it is the long-proven path
-- here, and it switches the desktop without touching window focus or app
-- activation, which focusing necessarily does.

local function query(args)
    -- No user-environment shell here: hs.execute(cmd, true) runs the command via
    -- `$SHELL -l -i -c`, which sources the whole zsh profile -- ~700ms per call,
    -- versus ~10ms for a plain sh. This fires on every keypress and YABAI is an
    -- absolute path, so there is nothing the profile is needed for.
    local out = hs.execute(string.format("%s -m query %s", YABAI, args))
    if not out or out == "" then return nil end
    local ok, decoded = pcall(hs.json.decode, out)
    if not ok then return nil end
    return decoded
end

-- Absolute index of the neighbouring space on the current display, or nil when
-- there is no space that way (so an edge press is a no-op instead of a surprise).
-- One query, not two: --spaces --display already flags the focused space, and
-- this runs synchronously on Hammerspoon's main thread on every keypress.
local function neighbour(direction)
    local onDisplay = query("--spaces --display")
    if not onDisplay then return nil end
    local current, first, last
    for _, sp in ipairs(onDisplay) do
        if sp.index then
            if sp["has-focus"] then current = sp.index end
            if not first or sp.index < first then first = sp.index end
            if not last or sp.index > last then last = sp.index end
        end
    end
    if not current then return nil end
    local want = current + (direction == "prev" and -1 or 1)
    if want < first or want > last then return nil end
    return want
end

-- Posts macOS's own "Switch to Desktop N" chord. setFlags is the load-bearing
-- part: the triggering chord's ctrl+shift is still physically held, and without
-- forcing the flags the posted event merges with the real modifier state into
-- ctrl+shift+N, which matches no shortcut.
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
            local index = type(target) == "number" and target or neighbour(target)
            if not index then return end
            hs.execute(string.format("%s -m window %d --space %d", YABAI, win:id(), index))
            local kc = KEYCODE[index]
            if kc then post(kc) else win:focus() end
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
