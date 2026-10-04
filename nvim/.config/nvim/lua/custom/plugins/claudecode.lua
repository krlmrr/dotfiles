return {
  "coder/claudecode.nvim",
  event = "VeryLazy", -- Start the IDE server so `claude` in another pane can /ide connect
  dependencies = {
    "folke/snacks.nvim",
  },
  opts = {},
  keys = {
    -- Visual only: normal <leader>a is treesitter's parameter swap
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
  },
}
