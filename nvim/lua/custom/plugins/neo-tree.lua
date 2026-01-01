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

    -- Override neo-tree's confirm to use vim.ui.select (dressing.nvim)
    local inputs = require("neo-tree.ui.inputs")
    local original_confirm = inputs.confirm
    inputs.confirm = function(message, callback)
      local title = " Confirm "
      if message:match("[Dd]elete") then
        title = " Delete "
      end
      vim.ui.select({ "Yes", "No" }, {
        prompt = title,
        kind = "confirmation",
      }, function(choice)
        if callback then
          callback(choice == "Yes")
        end
      end)
    end

    -- Also patch vim.fn.confirm for any fallback usage
    local original_fn_confirm = vim.fn.confirm
    vim.fn.confirm = function(msg, choices, default, type)
      if msg:match("Neo%-tree") or msg:match("[Dd]elete") then
        local title = " Confirm "
        if msg:match("[Dd]elete") then
          title = " Delete "
        end
        vim.ui.select({ "Yes", "No" }, {
          prompt = title,
        }, function(choice)
          -- This is async, so we can't return directly
          -- Neo-tree should be using inputs.confirm instead
        end)
        return 0
      end
      return original_fn_confirm(msg, choices, default, type)
    end

    -- Auto-refresh neo-tree on focus/idle
    vim.api.nvim_create_autocmd({ "FocusGained", "CursorHold" }, {
      callback = function()
        if package.loaded["neo-tree.sources.manager"] then
          require("neo-tree.sources.manager").refresh("filesystem")
        end
      end,
    })

    require('neo-tree').setup {
      use_popups_for_input = false, -- Use vim.ui.input (dressing.nvim)
      close_if_last_window = true,
      popup_border_style = "rounded",
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
          padding = 2,
        },
        icon = {
          padding = " ",
        },
        name = {
          use_git_status_colors = true,
        },
        -- Git status colors (use_git_status_colors = true):
        -- Added     = Green       | Staged    = Green
        -- Modified  = Yellow      | Unstaged  = Yellow/Orange
        -- Deleted   = Red         | Conflict  = Red
        -- Renamed   = Purple      | Ignored   = Gray
        -- Untracked = Orange
        git_status = {
          symbols = {
            added     = "",
            modified  = "",
            deleted   = "",
            renamed   = "",
            untracked = "",
            ignored   = "",
            unstaged  = "",
            staged    = "",
            conflict  = "",
          },
        },
        diagnostics = {
          symbols = {
            error = "",
            warn  = "",
            info  = "",
            hint  = "",
          },
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
            -- Neovide: disable scroll animation
            if vim.g.neovide then
              vim.g.neovide_scroll_animation_length = 0
            end
          end,
        },
        {
          event = "neo_tree_buffer_leave",
          handler = function()
            vim.cmd("highlight Cursor blend=0")
            -- Neovide: restore scroll animation
            if vim.g.neovide then
              vim.g.neovide_scroll_animation_length = 0.3
            end
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
