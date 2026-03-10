-- Theme switcher: detects macOS appearance and applies appropriate colorscheme
local M = {}

-- Theme-aware colors (used by other plugins)
M.colors = {
  dark = {
    accent = "#61afef",
    bg_highlight = "#3e4452",
    fg = "#abb2bf",
    fg_muted = "#5c6370",
    bg_float = "#282c34",
  },
  light = {
    accent = "#1e66f5",
    bg_highlight = "#dce0e8", -- Catppuccin Latte "crust" - matches neo-tree cursor line
    fg = "#4c4f69",
    fg_muted = "#8c8fa1",
    bg_float = "#eff1f5",
  },
}

function M.get_colors()
  return M.colors[vim.o.background] or M.colors.dark
end

-- Detect macOS appearance (returns "dark" or "light")
function M.get_system_appearance()
  local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result:match("Dark") then
      return "dark"
    end
  end
  return "light"
end

-- Apply plugin-specific highlights (called after colorscheme loads)
local function apply_plugin_highlights()
  local c = M.get_colors()

  -- Dashboard
  vim.api.nvim_set_hl(0, "DashboardShortCut", { fg = c.accent, bg = "NONE" })
  vim.api.nvim_set_hl(0, "DashboardShortCutCursor", { fg = c.accent, bg = c.bg_highlight })
  vim.api.nvim_set_hl(0, "DashboardHeader", { fg = c.fg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "DashboardMruTitle", { fg = c.fg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "DashboardMruIcon", { fg = c.fg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "DashboardFiles", { fg = c.fg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "DashboardFooter", { fg = c.fg, bg = "NONE" })

  -- Dressing
  vim.api.nvim_set_hl(0, "DressingInputBorder", { fg = c.accent, bg = c.bg_float })
  vim.api.nvim_set_hl(0, "DressingInputTitle", { fg = c.bg_float, bg = c.accent, bold = true })
  vim.api.nvim_set_hl(0, "DressingInputText", { fg = c.fg, bg = c.bg_float })
  vim.api.nvim_set_hl(0, "DressingInputNormalFloat", { bg = c.bg_float })
  vim.api.nvim_set_hl(0, "DressingSelectCursorLine", { bg = c.bg_highlight })

  -- Neo-tree
  vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { fg = c.fg, bold = false })
  vim.api.nvim_set_hl(0, "NeoTreeFileName", { fg = c.fg, bold = false })
  vim.api.nvim_set_hl(0, "NeoTreeRootName", { fg = c.fg, bold = false })
  vim.api.nvim_set_hl(0, "NeoTreeCursorLine", { bg = c.bg_highlight })

  -- Indent blankline / Rainbow
  vim.api.nvim_set_hl(0, "IblIndent", { fg = c.bg_highlight })

  -- Cursor line
  vim.api.nvim_set_hl(0, "CursorLine", { bg = c.bg_highlight })
end

-- Apply dark theme (onedark)
local function apply_dark_theme()
  vim.o.background = "dark"
  require('onedark').setup {
    style = 'dark',
    colors = {
      cyan = "#7aa2f7",
      orange = "#e5c07b",
    },
    highlights = {
      ["@keyword"] = { fg = '$purple' },
      ["@function.builtin"] = { fg = '$blue' },
      ["@type.builtin"] = { fg = '$yellow' },
      ["String"] = { fg = '$green' },
      ["@string"] = { fg = '$green' },
      ["Comment"] = { fg = '#61AEEF' },
      ["@comment"] = { fg = '#61AEEF' },
      ["@comment.lua"] = { fg = '#61AEEF' },
      ["@lsp.type.comment"] = { fg = '#61AEEF' },
      ["@lsp.type.comment.lua"] = { fg = '#61AEEF' },
      ["@lsp.type.function"] = { fg = '$blue', fmt = 'none' },
      ["@lsp.type.method"] = { fmt = 'none' },
      ["@lsp.type.class"] = { fmt = 'none' },
      ["@lsp.type.namespace"] = { fmt = 'none' },
      ["@lsp.typemod.function.declaration"] = { fmt = 'none' },
      ["@lsp.typemod.method.declaration"] = { fmt = 'none' },
      ["@tag"] = { fg = '$red' },
      ["@tag.delimiter"] = { fg = '$fg' },
      ["@tag.attribute"] = { fg = '$yellow' },
      ["@tag.builtin"] = { fg = '$red' },
      ["@tag.vue"] = { fg = '$red' },
      ["@tag.delimiter.vue"] = { fg = '$fg' },
      ["@tag.attribute.vue"] = { fg = '$yellow' },
      ["@tag.blade"] = { fg = '$red' },
      ["@tag.delimiter.blade"] = { fg = '$fg' },
      ["@tag.attribute.blade"] = { fg = '$yellow' },
      ["@punctuation.bracket.blade"] = { fg = '$yellow' },
      ["@variable.php"] = { fg = '$red' },
      ["@variable.php_only"] = { fg = '$red' },
      ["@punctuation.bracket.php"] = { fg = '$yellow' },
      ["@punctuation.bracket.php_only"] = { fg = '$yellow' },
      ["@variable"] = { fg = '$red' },
      ["@lsp.type.variable"] = { fg = '$red' },
      ["@lsp.type.variable.javascript"] = { fg = '$red' },
      ["@lsp.type.variable.typescript"] = { fg = '$red' },
      ["@lsp.type.variable.typescriptreact"] = { fg = '$red' },
      ["@lsp.type.variable.javascriptreact"] = { fg = '$red' },
      ["@variable.builtin"] = { fg = '$yellow' },
      ["@lsp.typemod.variable.defaultLibrary"] = { fg = '$yellow' },
      ["@function.call"] = { fg = '$blue' },
      ["@lsp.type.function.php"] = { fg = '$blue', fmt = 'none' },
      ["@operator"] = { fg = '$cyan' },
      ["@keyword.conditional.ternary"] = { fg = '$cyan' },
      ["@lsp.type.operator"] = { fg = '$cyan' },
      ["@lsp.type.operator.typescript"] = { fg = '$cyan' },
      ["@lsp.type.operator.typescriptreact"] = { fg = '$cyan' },
      ["@punctuation.delimiter"] = { fg = '$cyan' },
      ["@punctuation.delimiter.typescript"] = { fg = '$cyan' },
      ["@punctuation.delimiter.typescriptreact"] = { fg = '$cyan' },
      ["@text.html"] = { fg = '$fg' },
      ["@constant.blade"] = { fg = '$cyan' },
      ["@variable.blade"] = { fg = '$cyan' },
    },
  }
  require('onedark').load()

  -- Dark mode custom highlights
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#abb2bf", bg = "NONE" })
  vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBar", { fg = "#5c6370", bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBarNC", { fg = "#5c6370", bg = "NONE" })
  vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#848B98", bg = "NONE" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#5c6370", bg = "NONE" })
  vim.api.nvim_set_hl(0, "FloatTitle", { fg = "#abb2bf", bg = "NONE" })

  apply_plugin_highlights()
end

-- Apply light theme (catppuccin latte)
local function apply_light_theme()
  vim.o.background = "light"
  require('catppuccin').setup({
    flavour = "latte",
    transparent_background = false,
    integrations = {
      cmp = true,
      gitsigns = true,
      nvimtree = true,
      neotree = true,
      treesitter = true,
      indent_blankline = { enabled = true },
      native_lsp = { enabled = true },
      telescope = { enabled = true },
      dashboard = true,
    },
  })
  vim.cmd.colorscheme("catppuccin-latte")

  -- Light mode custom highlights
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#4c4f69", bg = "NONE" })
  vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBar", { fg = "#8c8fa1", bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBarNC", { fg = "#8c8fa1", bg = "NONE" })
  vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#8c8fa1", bg = "NONE" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#8c8fa1", bg = "NONE" })
  vim.api.nvim_set_hl(0, "FloatTitle", { fg = "#4c4f69", bg = "NONE" })

  apply_plugin_highlights()
end

-- Apply theme based on current system appearance
function M.apply()
  local appearance = M.get_system_appearance()
  if appearance == "light" then
    apply_light_theme()
  else
    apply_dark_theme()
  end
end

-- Toggle between light and dark (manual override)
function M.toggle()
  if vim.o.background == "dark" then
    apply_light_theme()
  else
    apply_dark_theme()
  end
end

-- Sync with system appearance (call on FocusGained)
function M.sync()
  local appearance = M.get_system_appearance()
  local current = vim.o.background
  if appearance ~= current then
    M.apply()
  end
end

return M
