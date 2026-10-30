hs.allowAppleScript(true)

-- Runs headless: no dock icon, no menu bar icon. Without this, any activation
-- of the app raises the console, since Hammerspoon assumes a dock click meant
-- to show something. Open it deliberately with: hs -c 'hs.openConsole()'
hs.openConsoleOnDockClick(false)

-- ── Remote control / inspection ─────────────────────────────────────────────
-- Loads the message port the `hs` CLI talks to, so this config can be reloaded
-- and inspected from a terminal (`hs -c 'hs.reload()'`, `hs -c '...'`) instead
-- of only from the menu bar. Useful precisely when Hammerspoon is misbehaving.
pcall(function() require("hs.ipc") end)

-- ── Move window to a space AND follow it ────────────────────────────────────
-- cmd+1..9 goes to that desktop; cmd+shift+1..9 moves the focused window to
-- that desktop and goes there too.
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
local KEYCODE = { [1]=18, [2]=19, [3]=20, [4]=21, [5]=23, [6]=22, [7]=26, [8]=28, [9]=25 }

local function post(kc)
    local down = hs.eventtap.event.newKeyEvent(kc, true)
    down:setFlags({ ctrl = true }); down:post()
    local up = hs.eventtap.event.newKeyEvent(kc, false)
    up:setFlags({ ctrl = true }); up:post()
end

local function click(type, point)
    local event = hs.eventtap.event.newMouseEvent(type, point)
    event:setFlags({})
    event:post()
end

local function titleBarGrabPoint(win)
    local zoom = hs.axuielement.windowElement(win):attributeValue("AXZoomButton")
    local zoomFrame = zoom and zoom:attributeValue("AXFrame")
    if zoomFrame then
        return hs.geometry.point(zoomFrame.x + zoomFrame.w + 6, zoomFrame.y + zoomFrame.h / 2)
    end
    local frame = win:frame()
    return hs.geometry.point(frame.x + 80, frame.y + 12)
end

local function moveAndFollow(index)
    return function()
        pcall(function()
            local win = hs.window.focusedWindow()
            if not win then return end
            local spaces = hs.spaces.spacesForScreen(win:screen())
            if not spaces or not spaces[index] or spaces[index] == hs.spaces.focusedSpace() then return end
            local types = hs.eventtap.event.types
            local grab = titleBarGrabPoint(win)
            local held = hs.geometry.point(grab.x + 1, grab.y)
            local mouse = hs.mouse.absolutePosition()
            click(types.leftMouseDown, grab)
            hs.timer.doAfter(0.06, function()
                click(types.leftMouseDragged, held)
                hs.timer.doAfter(0.06, function()
                    post(KEYCODE[index])
                    hs.timer.doAfter(0.7, function()
                        click(types.leftMouseUp, held)
                        hs.mouse.absolutePosition(mouse)
                    end)
                end)
            end)
        end)
    end
end

local moveFollowKeys = {}
pcall(function()
    for i = 1, 9 do
        table.insert(moveFollowKeys,
            hs.hotkey.bind({ "cmd" }, tostring(i), function() post(KEYCODE[i]) end))
        table.insert(moveFollowKeys,
            hs.hotkey.bind({ "cmd", "shift" }, tostring(i), moveAndFollow(i)))
    end
end)

local FOCUS_KEYS = { h = "West", j = "South", k = "North", l = "East" }

local function focusToward(direction)
    return function()
        local win = hs.window.focusedWindow()
        if win then win["focusWindow" .. direction](win, nil, nil, true) end
    end
end

local focusKeys = {}
for key, direction in pairs(FOCUS_KEYS) do
    table.insert(focusKeys, hs.hotkey.bind({ "alt" }, key, focusToward(direction)))
end

local GHOSTTY = "com.mitchellh.ghostty"

local function ghosttyOrNewWindow()
    local ghostty = hs.application.get(GHOSTTY)
    if ghostty and ghostty:isFrontmost() then
        ghostty:selectMenuItem({ "File", "New Window" })
    else
        hs.application.launchOrFocusByBundleID(GHOSTTY)
    end
end

local ghosttyKey = hs.hotkey.bind({ "cmd" }, "return", ghosttyOrNewWindow)

local ghosttyLinkClick = hs.eventtap.new(
    { hs.eventtap.event.types.leftMouseDown, hs.eventtap.event.types.leftMouseUp },
    function(event)
        local flags = event:getFlags()
        if not flags.ctrl or flags.cmd then return false end
        local app = hs.application.frontmostApplication()
        if not app or app:bundleID() ~= GHOSTTY then return false end
        event:setFlags({ cmd = true, shift = flags.shift, alt = flags.alt })
        return false
    end
)
ghosttyLinkClick:start()

local RESTART_DOCK_WHEN_DISPLAY_ADDED = true
local displayWatcher

if RESTART_DOCK_WHEN_DISPLAY_ADDED then
    local SECONDS_FOR_SPACES_TO_SETTLE = 2
    local knownScreenCount = #hs.screen.allScreens()
    local pendingDockRestart

    local function restartDockToRevivedDesktopShortcuts()
        hs.execute("/usr/bin/killall Dock")
    end

    local function restartDockWhenDisplayAdded()
        local screenCount = #hs.screen.allScreens()
        local displayWasAdded = screenCount > knownScreenCount
        knownScreenCount = screenCount
        if not displayWasAdded then return end
        if pendingDockRestart then pendingDockRestart:stop() end
        pendingDockRestart = hs.timer.doAfter(SECONDS_FOR_SPACES_TO_SETTLE, restartDockToRevivedDesktopShortcuts)
    end

    displayWatcher = hs.screen.watcher.new(restartDockWhenDisplayAdded):start()
end

-- ── Auto-reload this config when it changes ─────────────────────────────────
-- Saves a trip to the menu bar on every edit. Only reacts to .lua files, since
-- the watcher fires for anything in the directory.
--
-- Kept in a file-scope local on purpose: a pathwatcher that isn't referenced
-- gets garbage-collected and silently stops working. Same reason the eventtaps
-- and watchers above are held in locals.
local configWatcher = hs.pathwatcher.new(
    os.getenv("HOME") .. "/.hammerspoon/",
    function(files)
        for _, f in ipairs(files) do
            if f:sub(-4) == ".lua" then
                hs.reload()
                return
            end
        end
    end
):start()
