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

local KEYCODE = { [1]=18, [2]=19, [3]=20, [4]=21, [5]=23, [6]=22, [7]=26, [8]=28, [9]=25 }

local function post(kc)
    local down = hs.eventtap.event.newKeyEvent(kc, true)
    down:setFlags({ ctrl = true }); down:post()
    local up = hs.eventtap.event.newKeyEvent(kc, false)
    up:setFlags({ ctrl = true }); up:post()
end

local desktopKeys = {}
for i = 1, 9 do
    table.insert(desktopKeys, hs.hotkey.bind({ "cmd" }, tostring(i), function() post(KEYCODE[i]) end))
end

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
