-- Caps Lock → tap for Escape, hold for Control
-- Uses hidutil to remap Caps Lock → F18, then Hammerspoon handles F18.

-- Remap Caps Lock (0x39) to F18 (0x6D) via hidutil
hs.execute('/usr/bin/hidutil property --set \'{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}\'')

local f18KeyCode = 0x4F -- F18 in macOS key codes
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
            return true -- suppress F18
        elseif type == hs.eventtap.event.types.keyUp then
            local alone = capsAlone
            capsDown = false
            capsAlone = false
            if alone then
                hs.eventtap.keyStroke({}, "escape", 0)
            end
            return true -- suppress F18
        end
    end

    -- While caps is held, add ctrl flag to key events
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
