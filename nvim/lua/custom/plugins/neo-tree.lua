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
    vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { fg = "#abb2bf", bold = false })
    vim.api.nvim_set_hl(0, "NeoTreeFileName", { fg = "#abb2bf", bold = false })
    vim.api.nvim_set_hl(0, "NeoTreeRootName", { fg = "#abb2bf", bold = false })

    require('neo-tree').setup {
      close_if_last_window = true,
      window = {
        position = "right",
        width = 40,
        mappings = {},
      },
      default_component_configs = {
        indent = {
          with_markers = false,
        },
      },
      event_handlers = {
        {
          event = "neo_tree_buffer_enter",
          handler = function()
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false
            vim.opt_local.statuscolumn = ""
            -- Make q and :q quit Neovim when neo-tree is focused
            vim.keymap.set("n", "q", "<cmd>qa<cr>", { buffer = true, silent = true })
            vim.cmd("cnoreabbrev <buffer> q qa")
            vim.cmd("cnoreabbrev <buffer> q! qa!")
          end,
        },
      },
      filesystem = {
        follow_current_file = {
          enabled = true,
        },
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_hidden = false,
        },
      },
    }
  end,
}
