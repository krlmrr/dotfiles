return {
  'stevearc/conform.nvim',
  opts = {},
  config = function()
    require('conform').setup({
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        -- Vue uses eslint_d which runs Prettier through ESLint (via eslint-plugin-prettier)
        -- This gives you: Prettier formatting + Tailwind class sorting + Vue template rules
        -- All in a single pass - no more cursor jumping!
        vue = { "eslint_d" },
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
        eslint_d = {
          command = "eslint_d",
          args = { "--fix-to-stdout", "--stdin", "--stdin-filename", "$FILENAME" },
          stdin = true,
          -- Use local eslint config
          cwd = require("conform.util").root_file({
            "eslint.config.js",
            "eslint.config.mjs",
            "eslint.config.cjs",
            ".eslintrc.js",
            ".eslintrc.json",
            ".eslintrc.yml",
            ".eslintrc.yaml",
            ".eslintrc",
            "package.json",
          }),
        },
      },
      format_on_save = {
        lsp_fallback = true,
        timeout_ms = 3000,
      },
      format_after_save = {
        lsp_fallback = true,
      },
    })

    -- NOTE: The old BufWritePost autocmd for eslint --fix has been removed.
    -- ESLint now runs through conform via eslint_d, which includes Prettier
    -- via eslint-plugin-prettier. This eliminates the double-format and cursor jumping.
  end
}
