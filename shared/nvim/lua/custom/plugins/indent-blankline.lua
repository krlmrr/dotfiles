return {
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  dependencies = { 'HiPhish/rainbow-delimiters.nvim' },
  config = function()
    local highlight = {
      "RainbowGreen",
      "RainbowBlue",
      "RainbowViolet",
      "RainbowYellow",
      "RainbowRed",
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
    end)

    local rainbow = require('rainbow-delimiters')
    vim.g.rainbow_delimiters = {
      strategy = {
        [''] = rainbow.strategy['global'],
        html = rainbow.strategy['global'],
        vue = rainbow.strategy['global'],
        blade = rainbow.strategy['global'],
        javascript = rainbow.strategy['global'],
        typescript = rainbow.strategy['global'],
        php = rainbow.strategy['global'],
        php_only = rainbow.strategy['global'],
      },
      query = {
        [''] = 'rainbow-delimiters',
        lua = 'rainbow-blocks',
        html = 'rainbow-delimiters',
        vue = 'rainbow-delimiters',
        blade = 'rainbow-delimiters',
        php_only = 'rainbow-delimiters',
      },
      highlight = highlight,
    }

    -- Debounced rainbow-delimiters refresh (prevents excessive updates on every keystroke)
    local refresh_timer = nil
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      callback = function(args)
        if refresh_timer then
          refresh_timer:stop()
        end
        refresh_timer = vim.defer_fn(function()
          local rd = require('rainbow-delimiters')
          if rd.is_enabled(args.buf) then
            rd.disable(args.buf)
            rd.enable(args.buf)
          end
        end, 100)
      end,
    })

    require('ibl').setup {
      indent = { char = '│', highlight = "IblIndent" },
      scope = { enabled = true, highlight = highlight, show_start = false, show_end = false },
      exclude = { filetypes = { 'dashboard', 'alpha', 'starter' } },
    }
    -- IblIndent color is set by config.theme module
    hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
  end,
}
