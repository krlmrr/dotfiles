local paths = require("default.hypr.paths")

-- Omarchy's default envs.lua prepends $OMARCHY_PATH/bin, landing it ahead of
-- ~/.local/bin, so the omarchy-* overrides in linuxbin lose to the packaged
-- ones for everything Hyprland spawns.
local local_bin = paths.home .. "/.local/bin"

local kept = {}
for entry in (os.getenv("PATH") or ""):gmatch("[^:]+") do
  if entry ~= local_bin then
    table.insert(kept, entry)
  end
end
table.insert(kept, 1, local_bin)

hl.env("PATH", table.concat(kept, ":"))
