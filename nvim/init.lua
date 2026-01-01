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

-- Neovide settings (not supported in config.toml)
if vim.g.neovide then
  vim.g.neovide_padding_top = 40
  vim.g.neovide_padding_bottom = 0
  vim.g.neovide_padding_left = 40
  vim.g.neovide_padding_right = 40
  vim.g.neovide_cursor_animation_length = 0
  vim.g.neovide_cursor_trail_size = 0
  vim.g.neovide_floating_shadow = false
end

