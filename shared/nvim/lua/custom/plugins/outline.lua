return {
  'hedyhli/outline.nvim',
  cmd = { 'Outline', 'OutlineOpen' },
  keys = {
    { '<leader>o', '<cmd>Outline<cr>', desc = 'Toggle code outline' },
  },
  config = function()
    require('outline').setup({
      outline_window = {
        position = 'right',
        width = 30,
        relative_width = false,
        auto_close = false,
        show_numbers = false,
        show_relative_numbers = false,
        wrap = false,
      },
      symbols = {
        icons = {
          File = { icon = '', hl = 'Identifier' },
          Module = { icon = '', hl = 'Include' },
          Namespace = { icon = '', hl = 'Include' },
          Package = { icon = '', hl = 'Include' },
          Class = { icon = '', hl = 'Type' },
          Method = { icon = '', hl = 'Function' },
          Property = { icon = '', hl = 'Identifier' },
          Field = { icon = '', hl = 'Identifier' },
          Constructor = { icon = '', hl = 'Special' },
          Enum = { icon = '', hl = 'Type' },
          Interface = { icon = '', hl = 'Type' },
          Function = { icon = '', hl = 'Function' },
          Variable = { icon = '', hl = 'Constant' },
          Constant = { icon = '', hl = 'Constant' },
          String = { icon = '', hl = 'String' },
          Number = { icon = '', hl = 'Number' },
          Boolean = { icon = '', hl = 'Boolean' },
          Array = { icon = '', hl = 'Constant' },
          Object = { icon = '', hl = 'Type' },
          Key = { icon = '', hl = 'Type' },
          Null = { icon = '', hl = 'Type' },
          EnumMember = { icon = '', hl = 'Identifier' },
          Struct = { icon = '', hl = 'Structure' },
          Event = { icon = '', hl = 'Type' },
          Operator = { icon = '', hl = 'Identifier' },
          TypeParameter = { icon = '', hl = 'Identifier' },
        },
      },
      preview_window = {
        auto_preview = true,
        winhl = 'Normal:Normal',
      },
    })
  end,
}
