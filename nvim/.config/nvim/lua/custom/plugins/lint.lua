return {
  'mfussenegger/nvim-lint',
  ft = { 'php' }, -- Only load for filetypes with configured linters
  config = function()
    local lint = require('lint')

    lint.linters_by_ft = {
      php = { 'phpstan' },
    }

    -- Run on save
    vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
