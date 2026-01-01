return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
  opts = {
    views = {
      mini = {
        timeout = 3000,
        position = { row = -2 },
      },
    },
    lsp = {
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
    },
    presets = {
      bottom_search = true,
      command_palette = true,
      long_message_to_split = false,
      inc_rename = false,
      lsp_doc_border = true,
    },
    routes = {
      -- Skip noisy messages entirely (must be before general routing)
      { filter = { event = "msg_show", find = "written" }, opts = { skip = true } },
      { filter = { event = "msg_show", find = "lines in buffer" }, opts = { skip = true } },
      { filter = { event = "notify", find = "lines in buffer" }, opts = { skip = true } },
      { filter = { event = "msg_show", find = "E162" }, opts = { skip = true } },
      { filter = { event = "notify", find = "Initializing" }, opts = { skip = true } },
      { filter = { event = "msg_show", find = "Initializing" }, opts = { skip = true } },
      { filter = { event = "lsp", kind = "progress" }, opts = { skip = true } },
      { filter = { event = "notify", find = "No information available" }, opts = { skip = true } },
      { filter = { event = "msg_show", find = "No information available" }, opts = { skip = true } },
      { filter = { event = "notify", find = "window%-picker" }, opts = { skip = true } },
      { filter = { event = "notify", find = "[Ll]oading" }, opts = { skip = true } },
      { filter = { event = "msg_show", find = "[Ll]oading" }, opts = { skip = true } },
      { filter = { event = "msg_show", find = "modifiable" }, opts = { skip = true } },
      { filter = { event = "notify", find = "modifiable" }, opts = { skip = true } },
      { filter = { event = "msg_show", find = "Operation canceled" }, opts = { skip = true } },
      { filter = { event = "notify", find = "Operation canceled" }, opts = { skip = true } },
      -- Route remaining messages to mini view
      { filter = { event = "msg_show" }, view = "mini" },
      { filter = { event = "notify" }, view = "mini" },
    },
  },
}
