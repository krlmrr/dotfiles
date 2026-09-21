-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Close the current buffer
vim.keymap.set("n", "<leader>w", function()
  require("snacks").bufdelete()
end, { desc = "Close buffer" })
