-- Set project root and show dashboard when opening a directory
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local arg = vim.fn.argv(0)
    if arg ~= "" then
      if vim.fn.isdirectory(arg) == 1 then
        -- Directory passed: set as cwd and show dashboard
        vim.cmd("bd")
        vim.cmd("cd " .. vim.fn.fnameescape(arg))
        require('dashboard'):instance()
      else
        -- File passed: set parent directory as cwd
        local dir = vim.fn.fnamemodify(arg, ":p:h")
        vim.cmd("cd " .. vim.fn.fnameescape(dir))
      end
    end
  end,
})

-- Show winbar only when multiple editor splits exist (excludes neo-tree)
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "WinNew", "WinClosed" }, {
  callback = function()
    vim.schedule(function()
      local wins = vim.api.nvim_tabpage_list_wins(0)
      local editor_wins = {}
      for _, win in ipairs(wins) do
        if vim.api.nvim_win_is_valid(win) then
          local cfg = vim.api.nvim_win_get_config(win)
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.bo[buf].filetype
          if cfg.relative == '' and ft ~= 'neo-tree' then
            table.insert(editor_wins, win)
          end
        end
      end
      for _, win in ipairs(editor_wins) do
        pcall(function()
          if #editor_wins > 1 then
            vim.wo[win].winbar = '  %t'
          else
            vim.wo[win].winbar = ''
          end
        end)
      end
    end)
  end,
})

-- Force 4-space indentation for Vue files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "vue",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
    vim.opt_local.indentexpr = ""
  end,
})

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- Terminal settings
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.statuscolumn = ""
  end,
})
