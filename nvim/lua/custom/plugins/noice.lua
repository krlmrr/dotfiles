return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
  opts = {
    lsp = {
      -- Override markdown rendering so that cmp and other plugins use Treesitter
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
    },
    presets = {
      bottom_search = true,         -- Use a classic bottom cmdline for search
      command_palette = true,       -- Position the cmdline and popupmenu together
      long_message_to_split = true, -- Long messages sent to a split
      inc_rename = false,           -- Enables input dialog for inc-rename.nvim
      lsp_doc_border = true,        -- Add border to hover docs and signature help
    },
    routes = {
      -- Hide "written" messages
      {
        filter = {
          event = "msg_show",
          kind = "",
          find = "written",
        },
        opts = { skip = true },
      },
      -- Hide "no lines in buffer" messages
      {
        filter = {
          event = "msg_show",
          find = "lines in buffer",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "notify",
          find = "lines in buffer",
        },
        opts = { skip = true },
      },
      -- Show "No write since last change" only once
      {
        filter = {
          event = "msg_show",
          find = "E162",
        },
        opts = { skip = true },
      },
      -- Suppress "Initializing JS/TS server" messages
      {
        filter = {
          event = "notify",
          find = "Initializing",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "msg_show",
          find = "Initializing",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "lsp",
          kind = "progress",
          find = "Initializing",
        },
        opts = { skip = true },
      },
    },
  },
}
