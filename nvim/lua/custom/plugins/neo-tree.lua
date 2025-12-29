return {
  'nvim-neo-tree/neo-tree.nvim',
  branch = "v3.x",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { bg = "NONE" })

    require('neo-tree').setup {
      window = {
        position = "right",
      },
      filesystem = {
        follow_current_file = {
          enabled = true,
        },
      },
    }
  end,
}
