return {
  'mfussenegger/nvim-lint',
  ft = { 'php' }, -- Only load for filetypes with configured linters
  config = function()
    local lint = require('lint')

    lint.linters_by_ft = {
      php = { 'phpstan' },
    }

    local function phpstan_installed()
      local phpstan = lint.linters.phpstan
      local cmd = type(phpstan.cmd) == 'function' and phpstan.cmd() or phpstan.cmd
      return vim.fn.executable(cmd) == 1
    end

    vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
      callback = function()
        if phpstan_installed() then
          lint.try_lint()
        end
      end,
    })
  end,
}
