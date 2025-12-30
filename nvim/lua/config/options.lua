-- Leader keys
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable built-in plugins
vim.g.loaded_matchparen = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Line numbers
vim.wo.number = true
vim.wo.relativenumber = true
vim.o.numberwidth = 1
vim.opt.statuscolumn = "%=%{v:relnum?v:relnum:v:lnum}   "

-- Tabs and indentation
vim.o.tabstop = 4
vim.o.expandtab = true
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.autoindent = true
vim.o.breakindent = true

-- Search
vim.o.hlsearch = true
vim.o.ignorecase = true
vim.o.smartcase = true

-- UI
vim.o.wrap = false
vim.o.cursorline = false
vim.o.scrolloff = 10
vim.o.termguicolors = true
vim.wo.signcolumn = 'no'
vim.wo.foldcolumn = '0'

-- Files
vim.o.swapfile = false
vim.o.undofile = true

-- Mouse and clipboard
vim.o.mouse = 'a'
vim.o.clipboard = 'unnamedplus'

-- Performance
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Completion
vim.o.completeopt = 'menuone,noselect'

-- Misc
vim.opt.shortmess:append('s')

-- Diagnostics
vim.diagnostic.config({
  underline = false,
})

-- Inlay hints
vim.lsp.inlay_hint.enable(true)

-- Remove underline styling
vim.api.nvim_set_hl(0, "@lsp.type.function", {})
vim.api.nvim_set_hl(0, "@lsp.type.method", {})
vim.api.nvim_set_hl(0, "LspReferenceText", {})
vim.api.nvim_set_hl(0, "LspReferenceRead", {})
vim.api.nvim_set_hl(0, "LspReferenceWrite", {})
