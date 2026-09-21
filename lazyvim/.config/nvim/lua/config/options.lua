-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

vim.opt.relativenumber = false

-- No sign column at all: nothing gets a gutter icon, and the number column's
-- default minimum width of 4 (which would hold the space open regardless) drops
-- to the digits actually on screen. Note this takes the gitsigns bar with it.
vim.opt.signcolumn = "no"
vim.opt.numberwidth = 2
vim.g.autoformat = false

-- 4-space indentation by default
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

-- PHP: LazyVim's lang.php extra defaults to phpactor; use intelephense.
vim.g.lazyvim_php_lsp = "intelephense"
