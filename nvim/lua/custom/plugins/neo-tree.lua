---@diagnostic disable: undefined-global
return {
  'nvim-neo-tree/neo-tree.nvim',
  branch = "v3.x",
  cmd = "Neotree", -- Only load when Neotree command is called
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    local muted = "#abb2bf"
    vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { fg = muted, bold = false })
    vim.api.nvim_set_hl(0, "NeoTreeFileName", { fg = muted, bold = false })
    vim.api.nvim_set_hl(0, "NeoTreeRootName", { fg = muted, bold = false })
    vim.api.nvim_set_hl(0, "NeoTreeCursorLine", { bg = "#3e4452" })

    require('neo-tree').setup {
      close_if_last_window = true,
      window = {
        position = "right",
        width = 40,
        mappings = {
          ["<bs>"] = "none",
        },
      },
      default_component_configs = {
        indent = {
          with_markers = false,
        },
        name = {
          use_git_status_colors = false,
        },
      },
      event_handlers = {
        {
          event = "neo_tree_buffer_enter",
          handler = function()
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false
            vim.opt_local.statuscolumn = ""
            vim.opt_local.cursorline = true
            vim.wo.cursorlineopt = "line"
            vim.cmd("highlight Cursor blend=100")
            vim.opt.guicursor:append("a:Cursor/lCursor")
            -- Make q and :q quit Neovim when neo-tree is focused
            vim.keymap.set("n", "q", "<cmd>qa<cr>", { buffer = true, silent = true })
            vim.cmd("cnoreabbrev <buffer> q qa")
            vim.cmd("cnoreabbrev <buffer> q! qa!")
          end,
        },
        {
          event = "neo_tree_buffer_leave",
          handler = function()
            vim.cmd("highlight Cursor blend=0")
          end,
        },
      },
      filesystem = {
        use_libuv_file_watcher = true,
        hijack_netrw_behavior = "disabled",
        hide_root_node = true,
        bind_to_cwd = true,
        cwd_target = {
          sidebar = "global",
        },
        follow_current_file = {
          enabled = true,
        },
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_hidden = false,
          never_show = {
            ".DS_Store",
          },
        },
      },
    }
  end,
}
