-- Disable space in normal/visual mode
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Clear search highlight
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Exit insert mode
vim.keymap.set("i", "jj", "<ESC>", { desc = "Exit insert mode" })

-- Command mode shortcut
vim.keymap.set('n', ';', ':', { noremap = true, desc = "Command mode" })

-- Add punctuation at end of line
vim.keymap.set("i", ";;", "<Esc>A;<Esc>", { desc = "Add semicolon at end" })
vim.keymap.set("i", ",,", "<Esc>A,<Esc>", { desc = "Add comma at end" })

-- Toggle inlay hints
vim.keymap.set('n', '<leader>th', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = '[T]oggle inlay [H]ints' })

-- Diagnostics
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- Terminal
vim.keymap.set("n", "<leader>tt", "<cmd>botright split | term<cr><cmd>startinsert<cr>", { desc = "Open terminal" })
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Neo-tree
vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Toggle file tree" })

-- Buffers and windows
vim.keymap.set("n", "<leader>x", "<cmd>bd!<cr>", { desc = "Close buffer (force)" })
vim.keymap.set("n", "<leader>w", "<cmd>close<cr>", { desc = "Close split" })
vim.keymap.set("n", "<leader>s", "<cmd>w<cr>", { desc = "Save file" })

-- New vertical split with Telescope
vim.keymap.set("n", "<leader>v", function()
  vim.cmd('rightbelow vnew')
  local new_buf = vim.api.nvim_get_current_buf()
  require('telescope.builtin').find_files({
    hidden = true,
    cwd = vim.fn.getcwd(),
    attach_mappings = function(prompt_bufnr, map)
      local actions = require('telescope.actions')
      actions.close:enhance({
        post = function()
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(new_buf) and vim.api.nvim_buf_get_name(new_buf) == '' then
              vim.api.nvim_buf_delete(new_buf, { force = true })
            end
          end)
        end,
      })
      return true
    end,
  })
end, { desc = "New vertical split" })

-- Auto-indent on empty line
vim.keymap.set("n", "i", function()
  if vim.fn.getline('.') == '' then
    return '"_cc'
  else
    return 'i'
  end
end, { expr = true, noremap = true, desc = "Insert (auto-indent on empty)" })

-- Smart o/O (reuse blank lines)
vim.keymap.set("n", "o", function()
  local next_line = vim.fn.getline(vim.fn.line('.') + 1)
  if next_line == '' then
    return 'j"_cc'
  else
    return 'o'
  end
end, { expr = true, noremap = true, desc = "New line below (reuse blank)" })

vim.keymap.set("n", "O", function()
  local prev_line = vim.fn.getline(vim.fn.line('.') - 1)
  if prev_line == '' then
    return 'k"_cc'
  else
    return 'O'
  end
end, { expr = true, noremap = true, desc = "New line above (reuse blank)" })

-- Move to first non-blank after j/k
vim.keymap.set('n', 'j', 'j_', { noremap = true, silent = true, desc = "Down and first non-blank" })
vim.keymap.set('n', 'k', 'k_', { noremap = true, silent = true, desc = "Up and first non-blank" })
vim.keymap.set('n', '<Down>', 'j_', { noremap = true, silent = true, desc = "Down and first non-blank" })
vim.keymap.set('n', '<Up>', 'k_', { noremap = true, silent = true, desc = "Up and first non-blank" })
