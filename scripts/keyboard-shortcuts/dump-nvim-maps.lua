local out = {}
local scripts = {}
for _, s in ipairs(vim.fn.getscriptinfo()) do
  scripts[s.sid] = s.name
end

local lazy_owner = {}
local ok_cfg, Config = pcall(require, "lazy.core.config")
local ok_keys, Keys = pcall(require, "lazy.core.handler.keys")
local ok_plugin, Plugin = pcall(require, "lazy.core.plugin")
if ok_cfg and ok_keys and ok_plugin then
  for name, plugin in pairs(Config.plugins) do
    local ok, resolved = pcall(function()
      return Keys.resolve(Plugin.values(plugin, "keys", true))
    end)
    if ok then
      for _, k in pairs(resolved) do
        local modes = type(k.mode) == "table" and k.mode or { k.mode or "n" }
        for _, m in ipairs(modes) do
          local norm = vim.fn.keytrans(vim.api.nvim_replace_termcodes(k.lhs, true, true, true))
          lazy_owner[m .. "\0" .. norm] = { plugin = name, desc = k.desc }
        end
      end
    end
  end
end

for _, mode in ipairs({ "n", "x", "s", "o", "i", "c", "t" }) do
  for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
    local norm = vim.fn.keytrans(vim.api.nvim_replace_termcodes(m.lhs, true, true, true))
    local owner = lazy_owner[mode .. "\0" .. norm]
    local defined_in = ""
    if m.callback then
      local info = debug.getinfo(m.callback, "S")
      defined_in = info and info.source and info.source:gsub("^@", "") or ""
    end
    out[#out + 1] = {
      mode = mode,
      lhs = norm,
      defined_in = defined_in,
      desc = m.desc or (owner and owner.desc) or "",
      rhs = m.rhs or "",
      script = scripts[m.sid] or "",
      sid = m.sid or 0,
      lnum = m.lnum or 0,
      plugin = owner and owner.plugin or "",
    }
  end
end

local lsp = {}
local ok_lsp, LspKeys = pcall(require, "lazyvim.plugins.lsp.keymaps")
local lsp_spec = {}
local ok_o, resolved = pcall(function()
  return Plugin.values(Config.plugins["nvim-lspconfig"], "opts", false)
end)
if ok_o and resolved and resolved.servers and resolved.servers["*"] then
  lsp_spec = resolved.servers["*"].keys or {}
end
if #lsp_spec > 0 then
  for _, k in ipairs(lsp_spec) do
    lsp[#lsp + 1] = { lhs = k[1], desc = k.desc or "", mode = k.mode or "n" }
  end
elseif ok_lsp and LspKeys.get then
  for _, k in ipairs(LspKeys.get()) do
    lsp[#lsp + 1] = { lhs = k[1], desc = k.desc or "", mode = k.mode or "n" }
  end
end

local f = io.open(vim.env.DUMP_OUT, "w")
f:write(vim.json.encode({ maps = out, lsp = lsp, version = tostring(vim.version()) }))
f:close()
