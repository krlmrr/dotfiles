-- Git status colors (use_git_status_colors = true):
-- Added     = Green       | Staged    = Green
-- Modified  = Yellow      | Unstaged  = Yellow/Orange
-- Deleted   = Red         | Conflict  = Red
-- Renamed   = Purple      | Ignored   = Gray
-- Untracked = Orange

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
      commands = {
        file_details_float = function(state)
          local node = state.tree:get_node()
          if not node then return end

          local stat = vim.uv.fs_stat(node:get_id())
          local lines = {}
          local function add(label, value)
            table.insert(lines, string.format("%-8s  %s", label, value))
          end

          add("Name", node.name)
          add("Path", node:get_id())
          add("Type", node.type)

          if stat then
            local utils = require("neo-tree.utils")
            add("Size", utils.human_size(stat.size))
            add("Created", os.date("%Y-%m-%d %I:%M %p", stat.birthtime.sec))
            add("Modified", os.date("%Y-%m-%d %I:%M %p", stat.mtime.sec))
          end

          local width = 60
          local height = #lines
          local buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          local win = vim.api.nvim_open_win(buf, true, {
            relative = "editor",
            width = width,
            height = height,
            row = math.floor((vim.o.lines - height) / 2),
            col = math.floor((vim.o.columns - width) / 2),
            style = "minimal",
            border = "rounded",
            title = " File Details ",
            title_pos = "center",
          })
          vim.wo[win].winhighlight =
          "Normal:DressingInputText,NormalFloat:DressingInputNormalFloat,FloatBorder:DressingInputBorder,FloatTitle:DressingInputTitle"
          vim.wo[win].wrap = false
          vim.bo[buf].modifiable = false
          vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end, { buffer = buf })
          vim.keymap.set("n", "<Esc>", function() vim.api.nvim_win_close(win, true) end, { buffer = buf })
        end,
      },
      window = {
        position = "right",
        width = 40,
        mappings = {
          ["<bs>"] = "none",
          ["i"] = "file_details_float",
        },
      },
      -- Prevent Neo-tree from appearing in the middle of splits
      open_files_do_not_replace_types = { "terminal", "trouble", "qf", "toggleterm" },
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
          event = "neo_tree_window_before_open",
          handler = function()
            -- Always open on the far right by moving there first
            vim.cmd("wincmd l")
          end,
        },
        {
          event = "file_deleted",
          handler = function(args)
            local path = args.path or args
            local norm = vim.fn.fnamemodify(path, ":p")
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              local buf_name = vim.api.nvim_buf_get_name(buf)
              if buf_name ~= "" then
                local buf_norm = vim.fn.fnamemodify(buf_name, ":p")
                if buf_norm == norm or buf_norm:find(norm, 1, true) == 1 then
                  -- Switch windows showing this buffer to an empty buffer
                  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
                    vim.api.nvim_win_set_buf(win, vim.api.nvim_create_buf(true, false))
                  end
                  vim.api.nvim_buf_delete(buf, { force = true })
                end
              end
            end
          end,
        },
        {
          event = "neo_tree_buffer_enter",
          handler = function()
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false
            vim.opt_local.statuscolumn = ""
            vim.opt_local.cursorline = true
            vim.wo.cursorlineopt = "line"
            -- Make q and :q quit Neovim when neo-tree is focused
            vim.keymap.set("n", "q", "<cmd>qa<cr>", { buffer = true, silent = true })
            vim.cmd("cnoreabbrev <buffer> q qa")
            vim.cmd("cnoreabbrev <buffer> q! qa!")
            -- Neovide: disable scroll animation
            if vim.g.neovide then
              vim.g.neovide_scroll_animation_length = 0
            end

            -- Hide cursor in neo-tree (also handles returning from dialogs)
            local function hide_cursor()
              vim.cmd("highlight Cursor blend=100")
              vim.opt.guicursor:append("a:Cursor/lCursor")
            end
            hide_cursor()

            -- Re-hide cursor when returning to neo-tree from popups/dialogs
            vim.api.nvim_create_autocmd("WinEnter", {
              buffer = 0,
              callback = hide_cursor,
            })
          end,
        },
        {
          event = "neo_tree_buffer_leave",
          handler = function()
            vim.cmd("highlight Cursor blend=0")
            vim.opt.guicursor = vim.opt.guicursor - "a:Cursor/lCursor"
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
