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

        -- HTML/Blade tag colors (match Vue)
        ["@tag"] = { fg = '$red' },
        ["@tag.delimiter"] = { fg = '$fg' },
        ["@tag.attribute"] = { fg = '$yellow' },
        ["@tag.builtin"] = { fg = '$red' },

        -- Vue tag colors
        ["@tag.vue"] = { fg = '$red' },
        ["@tag.delimiter.vue"] = { fg = '$fg' },
        ["@tag.attribute.vue"] = { fg = '$yellow' },

        -- Blade-specific highlights (match Vue exactly)
        ["@tag.blade"] = { fg = '$red' },
        ["@tag.delimiter.blade"] = { fg = '$fg' },
        ["@tag.attribute.blade"] = { fg = '$yellow' },

        -- Blade brackets {{ }} {!! !!} ()
        ["@punctuation.bracket.blade"] = { fg = '$yellow' },

        -- PHP variables and brackets
        ["@variable.php"] = { fg = '$red' },
        ["@variable.php_only"] = { fg = '$red' },
        ["@punctuation.bracket.php"] = { fg = '$yellow' },
        ["@punctuation.bracket.php_only"] = { fg = '$yellow' },

        -- Variables (red like PHP)
        ["@variable"] = { fg = '$red' },
        ["@lsp.type.variable"] = { fg = '$red' },
        ["@lsp.type.variable.javascript"] = { fg = '$red' },
        ["@lsp.type.variable.typescript"] = { fg = '$red' },
        ["@lsp.type.variable.typescriptreact"] = { fg = '$red' },
        ["@lsp.type.variable.javascriptreact"] = { fg = '$red' },

        -- Additional HTML element highlights
        ["@text.html"] = { fg = '$fg' },
        ["@constant.blade"] = { fg = '$cyan' },
        ["@variable.blade"] = { fg = '$cyan' },
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
