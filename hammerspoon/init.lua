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
-- COSMIC-style "send to workspace and go there". macOS won't do it in one step
-- with SIP on: `yabai -m window --space N` is public API and works, but
-- `yabai -m space --focus N` needs the scripting addition, which SIP blocks.
-- So yabai moves the window and macOS does its own switching — we just post the
-- ctrl+N that System Settings ▸ Keyboard ▸ Shortcuts ▸ Mission Control already
-- binds ("Switch to Desktop N", enabled for 1-6 here).
--
-- These chords used to live in skhdrc as move-without-follow; they were removed
-- there because skhd's event tap would swallow the key before hs.hotkey saw it.
-- ctrl+shift+7..9 are still skhd's (move only) — desktops 7+ have no native
-- switch shortcut to follow with.
--
-- Everything is pcall-wrapped: a failure here must never break the Caps Lock
-- eventtaps above, which matter far more than this does.
local YABAI = "/opt/homebrew/bin/yabai"

-- Follow by posting macOS's own "Switch to Desktop N" shortcut through System
-- Events, so Apple does the switching and you get the normal side-scroll.
--
-- Three mechanisms were tried; this is the only one that both works and looks
-- native:
--   * hs.eventtap.keyStroke — silently does nothing. Synthetic events do not
--     trigger symbolichotkeys.
--   * hs.spaces.gotoSpace — works, and handles any index, but drives the
--     Mission Control interface, so every switch flashes Mission Control.
--   * osascript + System Events — works, and gives the real native animation.
--     Costs an interpreter spawn per press, and is capped at desktop 8 because
--     macOS has no ctrl+9 (symbolichotkeys stop at 125).
--
-- The window id comes from hs.window.focusedWindow(), not yabai: run from
-- Hammerspoon, `yabai -m window --space N` and `yabai -m query --windows
-- --window` both exit 0 having done nothing, because yabai reports no focused
-- window in that context. yabai's window ids are CGWindowIDs, so passing the id
-- explicitly sidesteps that.
-- Keycodes for macOS's own "Switch to Desktop N" shortcuts (symbolichotkeys
-- 118-126 = desktops 1-9, all ctrl+N and all enabled here). 127 is desktop 10
-- (ctrl+0) and is disabled, so 10+ has no native shortcut to post.
local KEYCODE = { [1]=18, [2]=19, [3]=20, [4]=21, [5]=23, [6]=22, [7]=26, [8]=28, [9]=25 }

local function flatSpaces()
    local flat = {}
    for _, scr in ipairs(hs.screen.allScreens()) do
        for _, id in ipairs(hs.spaces.spacesForScreen(scr:getUUID()) or {}) do
            table.insert(flat, id)
        end
    end
    return flat
end

local function currentIndex(flat)
    local focused = hs.spaces.focusedSpace()
    for i, id in ipairs(flat) do
        if id == focused then return i end
    end
end

-- Post the native shortcut, but only once SHIFT is physically released.
-- This is the subtle one: while ctrl+shift is still held, the synthetic ctrl+N
-- merges with the real modifier state and macOS sees ctrl+shift+N, which
-- matches no shortcut — so nothing happens and the window looks like it moved
-- without following. Verified directly: `key code 19 using control down`
-- switches space, `using {control down, shift down}` does not.
-- Physical ctrl still being held is fine — that is part of the chord we want.
-- Switch to a space. Prefers macOS's own "Switch to Desktop N" shortcut so the
-- animation is the native side-scroll; falls back to hs.spaces.gotoSpace only
-- where no such shortcut exists (desktop 10+ — 127/ctrl+0 is disabled).
-- gotoSpace works for any index but drives the Mission Control interface, so it
-- flashes; that is why it is the fallback and not the default.
--
-- The shift wait is the subtle part: while ctrl+shift is physically held, a
-- synthetic ctrl+N merges with the real modifier state and macOS sees
-- ctrl+shift+N, which matches nothing — the window moves and the view never
-- follows. Verified directly: `key code 19 using control down` switches space,
-- `using {control down, shift down}` does not. Physical ctrl still being held is
-- fine, it is part of the chord we want.
local function gotoIndex(idx, attempts)
    local kc = KEYCODE[idx]
    if not kc then -- no native shortcut (desktop 10+): accept the flash
        local flat = flatSpaces()
        if flat[idx] then hs.spaces.gotoSpace(flat[idx]) end
        return
    end
    attempts = attempts or 0
    if hs.eventtap.checkKeyboardModifiers().shift and attempts < 50 then
        hs.timer.doAfter(0.03, function() gotoIndex(idx, attempts + 1) end)
        return -- give up after ~1.5s rather than firing into a held chord
    end
    hs.execute(string.format(
        [[osascript -e 'tell application "System Events" to key code %d using control down']], kc), true)
end

-- target is a number, or "prev"/"next" resolved against the current space.
local function moveAndFollow(target)
    return function()
        local ok, err = pcall(function()
            local win = hs.window.focusedWindow()
            if not win then return end
            local flat = flatSpaces()
            local idx = target
            if target == "prev" or target == "next" then
                local cur = currentIndex(flat)
                if not cur then return end
                idx = (target == "prev") and (cur - 1) or (cur + 1)
            end
            if idx < 1 or idx > #flat then
                hs.alert.show("No space " .. tostring(idx), 0.7)
                return
            end
            hs.execute(string.format("%s -m window %d --space %d", YABAI, win:id(), idx), true)
            gotoIndex(idx)
        end)
        if not ok then
            hs.printf("moveAndFollow(%s) failed: %s", tostring(target), tostring(err))
        end
    end
end

local moveFollowKeys = {}
pcall(function()
    for i = 1, 9 do
        table.insert(moveFollowKeys,
            hs.hotkey.bind({ "ctrl", "shift" }, tostring(i), moveAndFollow(i)))
    end
    -- Plain ctrl+1..9 are macOS's own shortcuts and are deliberately NOT bound
    -- here: binding them would intercept the native switch and replace a smooth
    -- side-scroll with the Mission Control fallback.
    table.insert(moveFollowKeys, hs.hotkey.bind({ "ctrl", "shift" }, "left",  moveAndFollow("prev")))
    table.insert(moveFollowKeys, hs.hotkey.bind({ "ctrl", "shift" }, "right", moveAndFollow("next")))
end)
