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
vim.o.autoread = true

-- Auto-reload files when changed externally (real-time with libuv)
local watch_handles = {}
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local bufnr = args.buf
    local filepath = vim.api.nvim_buf_get_name(bufnr)
    if filepath == "" or not vim.uv.fs_stat(filepath) then return end

    -- Clean up existing watcher for this buffer
    if watch_handles[bufnr] then
      watch_handles[bufnr]:stop()
      watch_handles[bufnr] = nil
    end

    local handle = vim.uv.new_fs_event()
    watch_handles[bufnr] = handle
    handle:start(filepath, {}, function(err)
      if err then return end
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) and not vim.bo[bufnr].modified then
          vim.cmd("checktime " .. bufnr)
        end
      end)
    end)
  end,
})

vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(args)
    local handle = watch_handles[args.buf]
    if handle then
      handle:stop()
      watch_handles[args.buf] = nil
    end
  end,
})

-- Mouse and clipboard
vim.o.mouse = 'a'
vim.o.clipboard = 'unnamedplus'

-- Performance (updatetime also controls CursorHold delay)
vim.o.updatetime = 250

-- Auto-reload on cursor idle
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.cmd("checktime")
  end,
})
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
vim.lsp.inlay_hint.enable(false)

-- Remove underline styling
vim.api.nvim_set_hl(0, "@lsp.type.function", {})
vim.api.nvim_set_hl(0, "@lsp.type.method", {})
vim.api.nvim_set_hl(0, "LspReferenceText", {})
vim.api.nvim_set_hl(0, "LspReferenceRead", {})
vim.api.nvim_set_hl(0, "LspReferenceWrite", {})
