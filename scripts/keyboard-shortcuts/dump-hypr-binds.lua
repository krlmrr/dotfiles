package.path = "/usr/share/omarchy/?.lua;" .. os.getenv("HOME") .. "/.config/?.lua;" .. package.path

local function stub(called)
  return setmetatable({}, {
    __index = function()
      if called then
        return nil
      end
      return stub(false)
    end,
    __call = function() return stub(true) end,
  })
end

local current = "?"
local records = {}

local function esc(s)
  return (tostring(s):gsub('\\', '\\\\'):gsub('"', '\\"'))
end

hl = stub()
rawset(hl, "bind", function(keys, _, opts)
  opts = type(opts) == "table" and opts or {}
  records[#records + 1] = string.format('{"op":"bind","file":"%s","keys":"%s","desc":"%s"}', esc(current), esc(keys), esc(opts.description or ""))
end)
rawset(hl, "unbind", function(keys)
  records[#records + 1] = string.format('{"op":"unbind","file":"%s","keys":"%s"}', esc(current), esc(keys))
end)
rawset(hl, "on", function() end)
rawset(hl, "timer", function() end)

dofile("/usr/share/omarchy/default/hypr/helpers.lua")
if not o then
  o = _G.o
end

local function load(label, path)
  current = label
  local ok, err = pcall(dofile, path)
  if not ok then
    io.stderr:write(label .. ": " .. tostring(err) .. "\n")
  end
end

local base = "/usr/share/omarchy/default/hypr/bindings/"
for _, name in ipairs({ "media", "clipboard", "tiling", "utilities", "voxtype", "applications" }) do
  load(name, base .. name .. ".lua")
end
load("yours", os.getenv("HOME") .. "/.config/hypr/bindings.lua")

for _, r in ipairs(records) do
  print(r)
end
