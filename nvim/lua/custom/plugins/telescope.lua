return {
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
  },
  config = function()
    require('telescope').setup {
      defaults = {
        file_ignore_patterns = { ".DS_Store" },
        mappings = {
          i = {
            ['<C-u>'] = false,
            ['<C-d>'] = false,
            ['<Esc>'] = require('telescope.actions').close,
          },
        },
      },
    }

    pcall(require('telescope').load_extension, 'fzf')

    -- Use project root set by autocmds.lua
    local function find_project_root()
      local root = vim.g.project_root or vim.fn.getcwd()
      return root:gsub("/$", "")
    end

    -- Keymaps
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>?', builtin.oldfiles, { desc = '[?] Find recently opened files' })
    vim.keymap.set('n', '<leader><space>', builtin.buffers, { desc = '[ ] Find existing buffers' })
    vim.keymap.set('n', '<leader>/', function()
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })

    vim.keymap.set('n', '<leader>s/', function()
      builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' }
    end, { desc = '[S]earch [/] in Open Files' })
    vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    vim.keymap.set('n', '<leader>gf', builtin.git_files, { desc = 'Search [G]it [F]iles' })
    vim.keymap.set('n', '<leader>sf', function()
      builtin.find_files({ hidden = true, cwd = find_project_root() })
    end, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sw', function()
      builtin.grep_string({ cwd = find_project_root() })
    end, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>sg', function()
      builtin.live_grep({ cwd = find_project_root() })
    end, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
  end,
}
