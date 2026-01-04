return {
  'adalessa/laravel.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
    'tpope/vim-dotenv',
    'MunifTanjim/nui.nvim',
  },
  cmd = { 'Laravel' },
  keys = {
    { '<leader>la', '<cmd>Laravel artisan<cr>', desc = 'Laravel artisan' },
    { '<leader>lr', '<cmd>Laravel routes<cr>', desc = 'Laravel routes' },
    { '<leader>lm', '<cmd>Laravel related<cr>', desc = 'Laravel related files' },
  },
  ft = { 'php', 'blade' },
  config = function()
    require('laravel').setup({
      lsp_server = 'intelephense',
      features = {
        route_info = { enable = true },
      },
    })
  end,
}
