return {
  "stevearc/dressing.nvim",
  lazy = false, -- Load immediately to override vim.ui.input before neo-tree
  config = function()
    -- Highlights are set by config.theme module
    local cursor = require("config.cursor")

    -- Wrap vim.ui.select to customize confirmation dialogs
    local original_ui_select = vim.ui.select
    vim.ui.select = function(items, opts, on_choice)
      opts = opts or {}
      -- Only customize confirmation dialogs
      if opts.kind == "confirmation" then
        vim.defer_fn(cursor.hide, 10)
        local hints = { Yes = "y", No = "n" }
        opts.format_item = function(item)
          local hint = hints[item] or item:sub(1, 1):lower()
          return item .. " [" .. hint .. "]"
        end
        vim.defer_fn(function()
          local buf = vim.api.nvim_get_current_buf()
          -- Remove leading spaces from lines
          local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          for i, line in ipairs(lines) do
            lines[i] = line:gsub("^%s+", "")
          end
          vim.bo[buf].modifiable = true
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          vim.bo[buf].modifiable = false
          -- Add y/n keymaps
          for i, item in ipairs(items) do
            local key = hints[item] or item:sub(1, 1):lower()
            vim.keymap.set("n", key, function()
              vim.api.nvim_win_close(0, true)
              cursor.show()
              if on_choice then on_choice(item, i) end
            end, { buffer = buf, nowait = true })
          end
        end, 10)
        original_ui_select(items, opts, function(...)
          cursor.show()
          if on_choice then on_choice(...) end
        end)
      else
        original_ui_select(items, opts, on_choice)
      end
    end

    -- Wrap vim.ui.input to intercept neo-tree prompts before dressing sees them
    local original_ui_input = vim.ui.input
    vim.ui.input = function(opts, on_confirm)
      opts = opts or {}
      -- Neo-tree embeds "Neo-tree Popup\n..." in prompt
      local is_neotree = opts.prompt and (opts.prompt:match("Neo%-tree") or opts.prompt:match("neo%-tree"))
      if is_neotree then
        local title = " Input "
        local clear_default = true
        local is_new_file = opts.prompt:match("new file or directory")
        if is_new_file then
          title = " New File/Directory "
        elseif opts.prompt:match("[Rr]ename") or opts.prompt:match("Enter new name") then
          title = " Rename "
          clear_default = false -- Keep default for rename
        elseif opts.prompt:match("[Cc]opy") or opts.prompt:match("copy to") then
          title = " Copy To "
        elseif opts.prompt:match("[Mm]ove") or opts.prompt:match("move to") then
          title = " Move To "
          clear_default = false -- Keep default for move
        end
        opts.prompt = title
        if clear_default then
          opts.default = ""
        end
        -- Wrap callback to auto-add / for directories (no extension = directory)
        -- Use trailing * to force file creation (e.g., "Makefile*" → "Makefile")
        local wrapped_confirm = on_confirm
        if is_new_file then
          wrapped_confirm = function(value)
            if value and value ~= "" then
              if value:match("%*$") then
                value = value:sub(1, -2) -- Strip trailing *, create as file
              elseif not value:match("%/$") then
                local basename = value:match("[^/]+$") or value
                if not basename:match("%.") then
                  value = value .. "/"
                end
              end
            end
            on_confirm(value)
          end
        end
        -- Defer to fix timing issue on first open
        vim.defer_fn(function()
          original_ui_input(opts, wrapped_confirm)
        end, 10)
        return
      end
      return original_ui_input(opts, on_confirm)
    end

    require("dressing").setup({
      input = {
        enabled = true,
        default_prompt = "Input",
        title_pos = "center",
        border = "rounded",
        relative = "editor",
        prefer_width = 50,
        min_width = 30,
        start_in_insert = true,
        insert_only = false,
        mappings = {
          n = {
            ["<Esc>"] = "Close",
            ["<CR>"] = "Confirm",
          },
          i = {
            ["<Esc>"] = "Close",
            ["<C-c>"] = "Close",
            ["<CR>"] = "Confirm",
            ["<C-p>"] = "HistoryPrev",
            ["<C-n>"] = "HistoryNext",
          },
        },
        win_options = {
          winblend = 0,
          winhighlight = "Normal:DressingInputText,NormalFloat:DressingInputNormalFloat,FloatBorder:DressingInputBorder,FloatTitle:DressingInputTitle",
        },
        override = function(conf)
          conf.anchor = "NW"
          conf.row = math.floor((vim.o.lines - 6) / 2)
          conf.col = math.floor((vim.o.columns - 50) / 2) - 5
          return conf
        end,
        get_config = function(opts)
          -- Clear default for neo-tree new file/directory prompts
          if opts.prompt and opts.prompt:match("File/Directory") then
            return { default = "" }
          end
        end,
      },
      select = {
        enabled = true,
        backend = { "builtin" },
        get_config = function(opts)
          if opts.kind == "confirmation" then
            return { builtin = { show_numbers = false } }
          end
        end,
        builtin = {
          border = "rounded",
          relative = "editor",
          min_height = 0,
          max_height = 4,
          min_width = 20,
          max_width = 40,
          win_options = {
            winblend = 0,
            cursorline = true,
            signcolumn = "no",
            foldcolumn = "0",
            number = false,
            relativenumber = false,
            statuscolumn = "",
            winhighlight = "Normal:DressingInputText,NormalFloat:DressingInputNormalFloat,FloatBorder:DressingInputBorder,FloatTitle:DressingInputTitle,CursorLine:DressingSelectCursorLine",
          },
          show_numbers = true,
          override = function(conf)
            conf.anchor = "NW"
            conf.row = math.floor((vim.o.lines - 6) / 2)
            conf.col = math.floor((vim.o.columns - 30) / 2) - 5
            return conf
          end,
        },
      },
    })
  end,
}
