-- VS Code Neovim keymaps
-- Maps Neovim keybinds to VS Code equivalents

local vscode = require('vscode')
local call = vscode.call

-- Disable space in normal/visual mode
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Clear search highlight
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Exit insert mode
vim.keymap.set("i", "jj", "<ESC>", { desc = "Exit insert mode" })


-- Add punctuation at end of line
vim.keymap.set("i", ";;", "<Esc>A;<Esc>", { desc = "Add semicolon at end" })
vim.keymap.set("i", ",,", "<Esc>A,<Esc>", { desc = "Add comma at end" })

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

-- Auto-indent on paste
vim.keymap.set('n', 'p', 'p`[v`]=', { noremap = true, silent = true, desc = "Paste and indent" })
vim.keymap.set('n', 'P', 'P`[v`]=', { noremap = true, silent = true, desc = "Paste before and indent" })

-- Move to first non-blank after j/k
vim.keymap.set('n', 'j', 'j_', { noremap = true, silent = true, desc = "Down and first non-blank" })
vim.keymap.set('n', 'k', 'k_', { noremap = true, silent = true, desc = "Up and first non-blank" })
vim.keymap.set('n', '<Down>', 'j_', { noremap = true, silent = true, desc = "Down and first non-blank" })
vim.keymap.set('n', '<Up>', 'k_', { noremap = true, silent = true, desc = "Up and first non-blank" })

-- Move selected lines up/down in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Yank to end of line (consistent with D and C)
vim.keymap.set('n', 'Y', 'y$', { desc = "Yank to end of line" })

-- PHP dd() wrapper
vim.keymap.set('n', '<leader>dd', function()
  local line = vim.api.nvim_get_current_line()
  local indent = line:match('^(%s*)')
  local content = line:gsub('^%s*', ''):gsub(';%s*$', '')
  vim.api.nvim_set_current_line(indent .. 'dd(' .. content .. ');')
end, { desc = "Wrap line with dd()" })

-- Window navigation
vim.keymap.set("n", "<C-h>", function() call('workbench.action.focusLeftGroup') end, { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", function() call('workbench.action.focusBelowGroup') end, { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", function() call('workbench.action.focusAboveGroup') end, { desc = "Move to top window" })
vim.keymap.set("n", "<C-l>", function() call('workbench.action.focusRightGroup') end, { desc = "Move to right window" })

-- File tree (Neo-tree equivalent)
vim.keymap.set("n", "<leader>e", function() call('workbench.view.explorer') end, { desc = "Focus explorer" })

-- Buffers and windows
vim.keymap.set("n", "<leader>x", function() call('alwaysNew.closeEditor') end, { desc = "Close editor" })
vim.keymap.set("n", "<leader>w", function() call('alwaysNew.closeEditor') end, { desc = "Close editor" })
vim.keymap.set("n", "<leader>s", function() call('workbench.action.files.save') end, { desc = "Save file" })
vim.keymap.set("n", "<leader>v", function() call('workbench.action.splitEditorRight') end, { desc = "Split right" })

-- Telescope equivalents
vim.keymap.set('n', '<leader>sf', function() call('workbench.action.quickOpen') end, { desc = 'Search files' })
vim.keymap.set('n', '<leader>sg', function() call('workbench.action.findInFiles') end, { desc = 'Search by grep' })
vim.keymap.set('n', '<leader>?', function() call('workbench.action.openRecent') end, { desc = 'Recent files' })
vim.keymap.set('n', '<leader><space>', function() call('workbench.action.showAllEditors') end, { desc = 'Show all editors' })
vim.keymap.set('n', '<leader>/', function() call('actions.find') end, { desc = 'Search in buffer' })
vim.keymap.set('n', '<leader>gf', function() call('workbench.action.quickOpen') end, { desc = 'Git files' })
vim.keymap.set('n', '<leader>sd', function() call('workbench.actions.view.problems') end, { desc = 'Search diagnostics' })

-- Multi-cursor (ctrl+g - matches vim-visual-multi in terminal)
vim.keymap.set('n', '<C-g>', function() call('editor.action.addSelectionToNextFindMatch') end, { desc = 'Add cursor to next match' })
vim.keymap.set('i', '<C-g>', function() call('editor.action.addSelectionToNextFindMatch') end, { desc = 'Add cursor to next match' })
vim.keymap.set('n', '<leader>sk', function() call('workbench.action.openGlobalKeybindings') end, { desc = 'Search keymaps' })

-- LSP equivalents
vim.keymap.set('n', 'gd', function() call('editor.action.revealDefinition') end, { desc = 'Go to definition' })
vim.keymap.set('n', 'gr', function() call('editor.action.goToReferences') end, { desc = 'Go to references' })
vim.keymap.set('n', 'gI', function() call('editor.action.goToImplementation') end, { desc = 'Go to implementation' })
vim.keymap.set('n', 'gD', function() call('editor.action.revealDeclaration') end, { desc = 'Go to declaration' })
vim.keymap.set('n', 'K', function() call('editor.action.showHover') end, { desc = 'Hover' })
vim.keymap.set('n', '<C-k>', function() call('editor.action.triggerParameterHints') end, { desc = 'Signature help' })
vim.keymap.set('n', '<leader>rn', function() call('editor.action.rename') end, { desc = 'Rename' })
vim.keymap.set('n', '<leader>ca', function() call('editor.action.quickFix') end, { desc = 'Code action' })
vim.keymap.set('n', '<leader>D', function() call('editor.action.goToTypeDefinition') end, { desc = 'Type definition' })
vim.keymap.set('n', '<leader>ds', function() call('workbench.action.gotoSymbol') end, { desc = 'Document symbols' })
vim.keymap.set('n', '<leader>ws', function() call('workbench.action.showAllSymbols') end, { desc = 'Workspace symbols' })

-- Diagnostics
vim.keymap.set('n', '[d', function() call('editor.action.marker.prev') end, { desc = 'Previous diagnostic' })
vim.keymap.set('n', ']d', function() call('editor.action.marker.next') end, { desc = 'Next diagnostic' })
vim.keymap.set('n', '<leader>q', function() call('workbench.actions.view.problems') end, { desc = 'Problems panel' })

-- Git
vim.keymap.set('n', '<leader>gg', function() call('workbench.view.scm') end, { desc = 'Git source control' })
vim.keymap.set('n', '<leader>gb', function() call('git.blame.toggleEditorDecoration') end, { desc = 'Git blame toggle' })

-- Resize splits
vim.keymap.set('n', '<C-=>', function() call('workbench.action.increaseViewSize') end, { desc = 'Increase view size' })
vim.keymap.set('n', '<C-->', function() call('workbench.action.decreaseViewSize') end, { desc = 'Decrease view size' })

-- Testing (VS Code built-in)
vim.keymap.set('n', '<leader>ta', function() call('testing.runAll') end, { desc = 'Test all' })
vim.keymap.set('n', '<leader>tl', function() call('testing.reRunLastRun') end, { desc = 'Test last' })
vim.keymap.set('n', '<leader>tc', function() call('testing.runAtCursor') end, { desc = 'Test at cursor' })
vim.keymap.set('n', '<leader>tf', function() call('testing.runCurrentFile') end, { desc = 'Test file' })
