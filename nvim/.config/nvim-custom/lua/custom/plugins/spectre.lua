return {
  'nvim-pack/nvim-spectre',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = 'Spectre',
  keys = {
    { '<leader>S', '<cmd>Spectre<cr>', desc = 'Search and replace' },
    { '<leader>sw', function() require('spectre').open_visual({ select_word = true }) end, desc = 'Search current word' },
    { '<leader>sw', function() require('spectre').open_visual() end, mode = 'v', desc = 'Search selection' },
    { '<leader>sp', function() require('spectre').open_file_search({ select_word = true }) end, desc = 'Search in current file' },
  },
  config = function()
    require('spectre').setup({
      open_cmd = 'vnew',
      live_update = true,
      mapping = {
        ['toggle_line'] = {
          map = 'dd',
          cmd = "<cmd>lua require('spectre').toggle_line()<cr>",
          desc = 'toggle item',
        },
        ['enter_file'] = {
          map = '<cr>',
          cmd = "<cmd>lua require('spectre.actions').select_entry()<cr>",
          desc = 'open file',
        },
        ['send_to_qf'] = {
          map = '<leader>q',
          cmd = "<cmd>lua require('spectre.actions').send_to_qf()<cr>",
          desc = 'send to quickfix',
        },
        ['replace_cmd'] = {
          map = '<leader>c',
          cmd = "<cmd>lua require('spectre.actions').replace_cmd()<cr>",
          desc = 'input replace command',
        },
        ['show_option_menu'] = {
          map = '<leader>o',
          cmd = "<cmd>lua require('spectre').show_options()<cr>",
          desc = 'show options',
        },
        ['run_current_replace'] = {
          map = '<leader>rc',
          cmd = "<cmd>lua require('spectre.actions').run_current_replace()<cr>",
          desc = 'replace current line',
        },
        ['run_replace'] = {
          map = '<leader>R',
          cmd = "<cmd>lua require('spectre.actions').run_replace()<cr>",
          desc = 'replace all',
        },
        ['change_view_mode'] = {
          map = '<leader>v',
          cmd = "<cmd>lua require('spectre').change_view()<cr>",
          desc = 'change view mode',
        },
        ['resume_last_search'] = {
          map = '<leader>l',
          cmd = "<cmd>lua require('spectre').resume_last_search()<cr>",
          desc = 'resume last search',
        },
      },
    })
  end,
}
