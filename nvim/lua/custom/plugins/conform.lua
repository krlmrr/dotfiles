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
        timeout_ms = 3000,
      },
      format_after_save = {
        lsp_fallback = true,
      },
    })

    -- Run eslint --fix on Vue files after save
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "*.vue",
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local file = vim.fn.expand("%:p")
        local eslint = vim.fn.getcwd() .. "/node_modules/.bin/eslint"
        if vim.fn.executable(eslint) == 1 then
          vim.fn.jobstart({ eslint, "--fix", file }, {
            on_exit = function(_, exit_code)
              vim.schedule(function()
                if exit_code == 0 and vim.api.nvim_buf_is_valid(bufnr) then
                  vim.api.nvim_buf_call(bufnr, function()
                    vim.cmd("e!")
                  end)
                end
              end)
            end,
          })
        end
      end,
    })
  end
}
