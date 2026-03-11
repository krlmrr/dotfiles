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

local function startTaps()
    controlTap:start()
    keyDownTap:start()
    log.i("Caps Lock → Control/Escape started")
end

startTaps()

-- Restart eventtaps after sleep/wake and USB changes (undocking)
local watcher = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.systemDidWake then
        log.i("Restarting eventtaps after wake")
        controlTap:stop()
        keyDownTap:stop()
        startTaps()
    end
end)
watcher:start()

local usbWatcher = hs.usb.watcher.new(function(data)
    log.i("USB change detected, restarting eventtaps")
    controlTap:stop()
    keyDownTap:stop()
    startTaps()
end)
usbWatcher:start()
