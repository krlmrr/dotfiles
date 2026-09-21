-- Leader keys (needed everywhere)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

if vim.g.vscode then
  -- VS Code: only load keymaps that make sense
  require('config.vscode-keymaps')
else
  -- Terminal Neovim: full config
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
end
