return {
  'stevearc/conform.nvim',
  opts = {},
  config = function()
    require('conform').setup({
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        xml = { "xmlformat" },
        php = { "pint" },
        blade = { "blade-formatter" },
      },
      formatters = {
        pint = {
          command = "vendor/bin/pint",
          args = { "$FILENAME" },
          stdin = false,
        },
      },
      format_on_save = {
        lsp_fallback = true,
        timeout_ms = 500,
      },
      format_after_save = {
        lsp_fallback = true,
      },
    })
  end
}
