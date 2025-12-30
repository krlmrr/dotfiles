return {
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  dependencies = { 'HiPhish/rainbow-delimiters.nvim' },
  config = function()
    local highlight = {
      "RainbowRed",
      "RainbowYellow",
      "RainbowBlue",
      "RainbowOrange",
      "RainbowGreen",
      "RainbowViolet",
      "RainbowCyan",
    }

    local hooks = require "ibl.hooks"
    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
      vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
      vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
      vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
      vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
      vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
      vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
      vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#7aa2f7" })
      vim.api.nvim_set_hl(0, "@tag", {})
      vim.api.nvim_set_hl(0, "@tag.html", {})
      vim.api.nvim_set_hl(0, "@tag.vue", {})
      vim.api.nvim_set_hl(0, "@tag.delimiter", {})
      vim.api.nvim_set_hl(0, "@tag.delimiter.html", {})
      vim.api.nvim_set_hl(0, "@tag.delimiter.vue", {})
      vim.api.nvim_set_hl(0, "@punctuation.bracket", {})
      vim.api.nvim_set_hl(0, "@punctuation.bracket.vue", {})
    end)

    local rainbow = require('rainbow-delimiters')
    vim.g.rainbow_delimiters = {
      strategy = {
        [''] = rainbow.strategy['global'],
        html = rainbow.strategy['global'],
        vue = rainbow.strategy['global'],
        javascript = rainbow.strategy['global'],
        typescript = rainbow.strategy['global'],
        php = rainbow.strategy['global'],
      },
      query = {
        [''] = 'rainbow-delimiters',
        lua = 'rainbow-blocks',
      },
      highlight = highlight,
    }

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      callback = function(args)
        local rd = require('rainbow-delimiters')
        if rd.is_enabled(args.buf) then
          rd.disable(args.buf)
          rd.enable(args.buf)
        end
      end,
    })

    require('ibl').setup {
      indent = { char = '│', highlight = "IblIndent" },
      scope = { enabled = true, highlight = highlight, show_start = false, show_end = false },
      exclude = { filetypes = { 'dashboard', 'alpha', 'starter' } },
    }

    vim.api.nvim_set_hl(0, "IblIndent", { fg = "#3e4452" })
    hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
  end,
}
