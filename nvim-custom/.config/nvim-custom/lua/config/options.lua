-- Disable built-in plugins
vim.g.loaded_matchparen = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Line numbers
vim.wo.number = true
vim.wo.relativenumber = true
vim.o.numberwidth = 1

function _G.StatusColumn()
  local lnum = vim.v.lnum
  local relnum = vim.v.relnum
  if relnum == 0 then
    return '%#CursorLineNr#' .. lnum .. '%*   '
  else
    return relnum .. '   '
  end
end
vim.opt.statuscolumn = '%=%{%v:lua.StatusColumn()%}'

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
vim.o.sidescrolloff = 0
vim.o.termguicolors = true
vim.wo.signcolumn = 'no'
vim.wo.foldcolumn = '0'
vim.o.laststatus = 3 -- Global statusline (works with lualine globalstatus)
vim.o.cmdheight = 1

-- Files
vim.o.swapfile = false
vim.o.undofile = true
vim.o.autoread = true

-- Auto-reload files when changed externally (real-time with libuv)
local watch_handles = {}
vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function(args)
    local bufnr = args.buf
    local filepath = vim.api.nvim_buf_get_name(bufnr)
    if filepath == '' or not vim.uv.fs_stat(filepath) then
      return
    end

    -- Clean up existing watcher for this buffer
    if watch_handles[bufnr] then
      watch_handles[bufnr]:stop()
      watch_handles[bufnr] = nil
    end

    local handle = vim.uv.new_fs_event()
    watch_handles[bufnr] = handle
    handle:start(filepath, {}, function(err)
      if err then
        return
      end
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) and not vim.bo[bufnr].modified then
          vim.cmd('checktime ' .. bufnr)
        end
      end)
    end)
  end,
})

vim.api.nvim_create_autocmd('BufDelete', {
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

-- Prevent scrolling past end of file with mouse
vim.keymap.set({ 'n', 'v', 'i' }, '<ScrollWheelDown>', function()
  local win_height = vim.api.nvim_win_get_height(0)
  local last_line = vim.fn.line '$'
  local top_line = vim.fn.line 'w0'
  -- Only scroll if there's more content below
  if top_line + win_height <= last_line then
    return '<ScrollWheelDown>'
  end
  return ''
end, { expr = true, silent = true })

-- Only allow horizontal scrolling when content is wider than window
vim.keymap.set({ 'n', 'v', 'i' }, '<ScrollWheelLeft>', function()
  local win_width = vim.api.nvim_win_get_width(0)
  local longest = 0
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, vim.fn.line 'w0' - 1, vim.fn.line 'w$', false)) do
    longest = math.max(longest, vim.fn.strdisplaywidth(line))
  end
  if longest > win_width then
    return '<ScrollWheelLeft>'
  end
  return ''
end, { expr = true, silent = true })

vim.keymap.set({ 'n', 'v', 'i' }, '<ScrollWheelRight>', function()
  local win_width = vim.api.nvim_win_get_width(0)
  local longest = 0
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, vim.fn.line 'w0' - 1, vim.fn.line 'w$', false)) do
    longest = math.max(longest, vim.fn.strdisplaywidth(line))
  end
  if longest > win_width then
    return '<ScrollWheelRight>'
  end
  return ''
end, { expr = true, silent = true })

-- Keep cursor centered after window resize
vim.api.nvim_create_autocmd('WinResized', {
  callback = function()
    for _, win in ipairs(vim.v.event.windows) do
      if vim.api.nvim_win_is_valid(win) then
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.bo[buf].filetype
        -- Skip special buffers
        if ft ~= 'neo-tree' and ft ~= 'dashboard' and ft ~= '' then
          vim.api.nvim_win_call(win, function()
            vim.cmd 'normal! zz'
          end)
        end
      end
    end
  end,
})

-- Equalize splits on terminal resize (excluding neo-tree)
vim.api.nvim_create_autocmd('VimResized', {
  callback = function()
    -- Get neo-tree width if it exists
    local neotree_width = 0
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == 'neo-tree' then
        neotree_width = vim.api.nvim_win_get_width(win)
        break
      end
    end
    -- Equalize all windows then restore neo-tree width
    vim.cmd 'wincmd ='
    if neotree_width > 0 then
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == 'neo-tree' then
          vim.api.nvim_win_set_width(win, neotree_width)
          break
        end
      end
    end
  end,
})

-- Performance (updatetime also controls CursorHold delay)
vim.o.updatetime = 250

-- Auto-reload on cursor idle (skip special windows)
vim.api.nvim_create_autocmd('CursorHold', {
  callback = function()
    if vim.fn.getcmdwintype() ~= '' then
      return
    end
    vim.cmd 'checktime'
  end,
})
vim.o.timeoutlen = 300

-- Completion
vim.o.completeopt = 'menuone,noselect'

-- Misc
vim.opt.shortmess:append 's'

-- Diagnostics
vim.diagnostic.config {
  underline = false,
}

-- Inlay hints
vim.lsp.inlay_hint.enable(false)

-- Remove underline styling
vim.api.nvim_set_hl(0, '@lsp.type.function', {})
vim.api.nvim_set_hl(0, '@lsp.type.method', {})
vim.api.nvim_set_hl(0, 'LspReferenceText', {})
vim.api.nvim_set_hl(0, 'LspReferenceRead', {})
vim.api.nvim_set_hl(0, 'LspReferenceWrite', {})
