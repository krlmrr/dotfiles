return {
  'navarasu/onedark.nvim',
  priority = 1000,
  config = function()
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
        ["@lsp.type.function"] = { fmt = 'none' },
        ["@lsp.type.method"] = { fmt = 'none' },
        ["@lsp.type.class"] = { fmt = 'none' },
        ["@lsp.type.namespace"] = { fmt = 'none' },
        ["@lsp.typemod.function.declaration"] = { fmt = 'none' },
        ["@lsp.typemod.method.declaration"] = { fmt = 'none' },
      },
    }
    require('onedark').load()

    -- Custom highlights
    vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "WinBar", { fg = "#5c6370", bg = "NONE" })
    vim.api.nvim_set_hl(0, "WinBarNC", { fg = "#5c6370", bg = "NONE" })
    vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#848B98", bg = "NONE" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
  end,
}
