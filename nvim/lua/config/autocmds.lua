-- Store initial working directory before any autocmds change it
vim.g.project_root = vim.fn.getcwd()

-- Set project root and show dashboard when opening a directory
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local arg = vim.fn.argv(0)
    if arg ~= "" then
      -- Get absolute path without trailing slash
      local abs_arg = vim.fn.fnamemodify(arg, ":p"):gsub("/$", "")
      if vim.fn.isdirectory(abs_arg) == 1 then
        -- Directory passed: set as cwd and show dashboard
        vim.cmd("bd")
        vim.cmd("cd " .. vim.fn.fnameescape(abs_arg))
        vim.g.project_root = abs_arg
        require('dashboard'):instance()
      else
        -- File passed: find project root (git) or use file's parent
        local file_dir = vim.fn.fnamemodify(abs_arg, ":h")
        local git_root = vim.fn.systemlist('git -C ' .. vim.fn.shellescape(file_dir) .. ' rev-parse --show-toplevel')[1]
        local dir = (vim.v.shell_error == 0 and git_root and vim.fn.isdirectory(git_root) == 1) and git_root or file_dir
        if vim.fn.isdirectory(dir) == 1 then
          vim.cmd("cd " .. vim.fn.fnameescape(dir))
          vim.g.project_root = dir
        end
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

-- Force 4-space indentation for all filetypes
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
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

-- Show "Saved." on file write
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    vim.cmd('echo "Saved."')
  end,
})
