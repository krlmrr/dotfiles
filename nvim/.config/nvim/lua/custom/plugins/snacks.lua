local function project_root()
  return (vim.g.project_root or vim.fn.getcwd()):gsub('/$', '')
end

return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    picker = {
      enabled = true,
      exclude = { '.DS_Store' },
    },
  },
  keys = {
    { '<leader>ff', function() Snacks.picker.files { cwd = project_root(), hidden = true, ignored = true } end, desc = '[F]ind [F]iles' },
    { '<leader>gf', function() Snacks.picker.git_files() end, desc = 'Search [G]it [F]iles' },
    { '<leader>?', function() Snacks.picker.recent() end, desc = '[?] Find recently opened files' },
    { '<leader><space>', function() Snacks.picker.buffers() end, desc = '[ ] Find existing buffers' },
    { '<leader>/', function() Snacks.picker.lines() end, desc = '[/] Fuzzily search in current buffer' },

    { '<leader>sg', function() Snacks.picker.grep { cwd = project_root() } end, desc = '[S]earch by [G]rep' },
    { '<leader>sw', function() Snacks.picker.grep_word { cwd = project_root() } end, desc = '[S]earch current [W]ord' },
    { '<leader>s/', function() Snacks.picker.grep_buffers() end, desc = '[S]earch [/] in Open Files' },

    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = '[S]earch [D]iagnostics' },
    { '<leader>sr', function() Snacks.picker.resume() end, desc = '[S]earch [R]esume' },
    { '<leader>sk', function() Snacks.picker.keymaps() end, desc = '[S]earch [K]eymaps' },
    { '<leader>sh', function() Snacks.picker.help() end, desc = '[S]earch [H]elp' },
    { '<leader>ss', function() Snacks.picker.pickers() end, desc = '[S]earch [S]elect picker' },
  },
}
