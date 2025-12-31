return {
  'nvim-lualine/lualine.nvim',
  config = function()
    local custom_theme = {
      normal = {
        a = { fg = '#abb2bf', bg = 'NONE' },
        b = { fg = '#abb2bf', bg = 'NONE' },
        c = { fg = '#5c6370', bg = 'NONE' },
        x = { fg = '#abb2bf', bg = 'NONE' },
        y = { fg = '#abb2bf', bg = 'NONE' },
        z = { fg = '#282c34', bg = '#98c379', gui = 'bold' },
      },
      insert = {
        z = { fg = '#282c34', bg = '#61afef', gui = 'bold' },
      },
      visual = {
        z = { fg = '#282c34', bg = '#c678dd', gui = 'bold' },
      },
      replace = {
        z = { fg = '#282c34', bg = '#e06c75', gui = 'bold' },
      },
      command = {
        z = { fg = '#282c34', bg = '#e5c07b', gui = 'bold' },
      },
      inactive = {
        a = { fg = '#5c6370', bg = '#3e4452' },
        b = { fg = '#5c6370', bg = 'NONE' },
        c = { fg = '#5c6370', bg = 'NONE' },
        z = { fg = '#5c6370', bg = '#3e4452' },
      },
    }

    require('lualine').setup {
      options = {
        icons_enabled = true,
        theme = custom_theme,
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        globalstatus = true,
        disabled_filetypes = {
          statusline = { 'dashboard' },
        },
      },
      sections = {
        lualine_a = { 'branch', 'diff' },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {
          { 'filetype', fmt = function(str)
            if str == 'neo-tree' then return '' end
            if str == 'TelescopePrompt' then return '' end
            if str == 'php' then return 'PHP' end
            return str:sub(1, 1):upper() .. str:sub(2)
          end },
        },
        lualine_z = { { 'mode', separator = { left = '\u{e0b2}' } } },
      },
    }
  end,
}
