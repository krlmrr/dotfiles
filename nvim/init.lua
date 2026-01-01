-- Load configuration modules
require('config.options')
require('config.autocmds')

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- Load plugins
require('lazy').setup({
  { import = 'custom.plugins' },
}, {})

-- Load keymaps after plugins
require('config.keymaps')
require('config.vim-motions')

-- Neovide configuration
if vim.g.neovide then
  vim.g.neovide_title_hidden = true
  vim.opt.linespace = 14
  vim.g.neovide_padding_top = 20
  vim.g.neovide_padding_bottom = 10
  vim.g.neovide_padding_left = 20
  vim.g.neovide_padding_right = 20
  vim.g.neovide_cursor_animation_length = 0
  vim.g.neovide_cursor_trail_size = 0
end
