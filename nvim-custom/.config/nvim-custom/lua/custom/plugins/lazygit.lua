return {
  "kdheepak/lazygit.nvim",
  lazy = true,
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
  },
  config = function()
    vim.g.lazygit_floating_window_use_plenary = 0
    vim.g.lazygit_use_neovim_remote = 1
    vim.g.lazygit_floating_window_winblend = 0
    vim.g.lazygit_floating_window_scaling_factor = 1
    vim.g.lazygit_floating_window_border_chars = {'', '', '', '', '', '', '', ''}
    -- Darker terminal blue for lazygit selection visibility
    vim.g.terminal_color_4 = "#3e4452"
    vim.g.terminal_color_12 = "#3e4452"
    -- Transparent floating window background
    vim.api.nvim_set_hl(0, "LazyGitFloat", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "LazyGitBorder", { bg = "NONE" })
    -- Close lazygit with Escape
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "*lazygit*",
      callback = function()
        vim.keymap.set("t", "<Esc>", "<cmd>close<cr>", { buffer = true, desc = "Close lazygit" })
      end,
    })
  end,
}
