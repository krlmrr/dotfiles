return {
  "stevearc/dressing.nvim",
  lazy = false, -- Load immediately to override vim.ui.input before neo-tree
  config = function()
    -- Custom highlights for dressing
    vim.api.nvim_set_hl(0, "DressingInputBorder", { fg = "#61AFEF", bg = "NONE" })
    vim.api.nvim_set_hl(0, "DressingInputTitle", { fg = "#282c34", bg = "#61AFEF", bold = true })
    vim.api.nvim_set_hl(0, "DressingInputText", { fg = "#abb2bf", bg = "NONE" })
    vim.api.nvim_set_hl(0, "DressingInputNormalFloat", { bg = "NONE" })

    -- Wrap vim.ui.input to intercept neo-tree prompts before dressing sees them
    local original_ui_input = vim.ui.input
    vim.ui.input = function(opts, on_confirm)
      opts = opts or {}
      -- Neo-tree embeds "Neo-tree Popup\n..." in prompt
      local is_neotree = opts.prompt and (opts.prompt:match("Neo%-tree") or opts.prompt:match("neo%-tree"))
      if is_neotree then
        local title = " Input "
        local clear_default = true
        if opts.prompt:match("new file or directory") then
          title = " New File/Directory "
        elseif opts.prompt:match("[Rr]ename") then
          title = " Rename "
          clear_default = false -- Keep default for rename
        elseif opts.prompt:match("[Cc]opy") then
          title = " Copy To "
        elseif opts.prompt:match("[Mm]ove") then
          title = " Move To "
        end
        opts.prompt = title
        if clear_default then
          opts.default = ""
        end
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
        builtin = {
          border = "rounded",
          relative = "editor",
          min_height = 0,
          max_height = 4,
          min_width = 20,
          max_width = 40,
          win_options = {
            winblend = 0,
            winhighlight = "Normal:DressingInputText,NormalFloat:DressingInputNormalFloat,FloatBorder:DressingInputBorder,FloatTitle:DressingInputTitle",
          },
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
