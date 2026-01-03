return {
  'stevearc/conform.nvim',
  opts = {},
  config = function()
    require('conform').setup({
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        vue = { "prettier" },
        json = { "prettier" },
        xml = { "xmlformat" },
        php = { "pint" },
        blade = { "blade-formatter", "pint", stop_after_first = true },
      },
      formatters = {
        pint = {
          command = "vendor/bin/pint",
          args = { "$FILENAME" },
          stdin = false,
        },
        prettier = {
          command = function()
            local local_prettier = vim.fn.getcwd() .. "/node_modules/.bin/prettier"
            if vim.fn.executable(local_prettier) == 1 then
              return local_prettier
            end
            return "prettier"
          end,
        },
        ["blade-formatter"] = {
          command = function()
            local local_blade = vim.fn.getcwd() .. "/node_modules/.bin/blade-formatter"
            if vim.fn.executable(local_blade) == 1 then
              return local_blade
            end
            return "blade-formatter"
          end,
          args = { "--stdin", "--wrap-attributes", "force-expand-multiline", "--indent-size", "4", "--indent-inner-html" },
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
