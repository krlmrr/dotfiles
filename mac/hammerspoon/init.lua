-- Caps Lock → tap for Escape, hold for Control
-- Uses hidutil to remap Caps Lock → F18, then Hammerspoon handles F18.

local log = hs.logger.new("capslock", "info")

local function applyHidutil(reason)
    log.i("Applying hidutil mapping: " .. reason)
    hs.execute('/usr/bin/hidutil property --set \'{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}\'')
end

applyHidutil("init")

-- Re-apply after wake/unlock
local sleepWatcher = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.systemDidWake
        or event == hs.caffeinate.watcher.screensDidWake
        or event == hs.caffeinate.watcher.sessionDidBecomeActive
        or event == hs.caffeinate.watcher.screensDidUnlock then
        hs.timer.doAfter(1, function() applyHidutil("wake/unlock") end)
    end
end)
sleepWatcher:start()

-- Re-apply when USB keyboard connected
local usbWatcher = hs.usb.watcher.new(function(data)
    if data.eventType == "added" then
        log.i("USB device added: " .. (data.productName or "unknown"))
        hs.timer.doAfter(1, function() applyHidutil("usb-added") end)
    end
end)
usbWatcher:start()

-- Eventtap for F18 → Escape/Control
local f18KeyCode = 0x4F
local capsDown = false
local capsAlone = true

local capsWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp }, function(event)
    local keyCode = event:getKeyCode()
    local type = event:getType()

    if keyCode == f18KeyCode then
        if type == hs.eventtap.event.types.keyDown then
            if not capsDown then
                capsDown = true
                capsAlone = true
            end
            return true
        elseif type == hs.eventtap.event.types.keyUp then
            local alone = capsAlone
            capsDown = false
            capsAlone = false
            if alone then
                hs.timer.doAfter(0, function()
                    hs.eventtap.keyStroke({}, "escape", 50000)
                end)
            end
            return true
        end
    end

    if capsDown then
        if type == hs.eventtap.event.types.keyDown or type == hs.eventtap.event.types.keyUp then
            capsAlone = false
            local flags = event:getFlags()
            flags.ctrl = true
            event:setFlags(flags)
        end
    end

    return false
end)

capsWatcher:start()
log.i("Eventtap started")

-- Monitor eventtap health every 30s
hs.timer.doEvery(30, function()
    if not capsWatcher:isEnabled() then
        log.w("Eventtap died — restarting")
        capsWatcher:start()
    end
end)

log.i("Config loaded successfully")
