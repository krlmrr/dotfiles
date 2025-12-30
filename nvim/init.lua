vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.loaded_matchparen = 1 -- Disable matching bracket highlighting

vim.opt.statuscolumn = "%=%{v:relnum?v:relnum:v:lnum}   "

vim.o.tabstop = 4             -- A TAB character looks like 4 spaces
vim.o.expandtab = true        -- Pressing the TAB key will insert spaces instead of a TAB character
vim.o.softtabstop = 4         -- Number of spaces inserted instead of a TAB character
vim.o.shiftwidth = 4          -- Number of spaces inserted when indenting
vim.o.swapfile = false        -- Disable swap files
vim.o.scrolloff = 10
-- Show winbar only when multiple splits exist
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "WinNew", "WinClosed" }, {
  callback = function()
    vim.schedule(function()
      local wins = vim.api.nvim_tabpage_list_wins(0)
      -- Count only non-floating windows
      local real_wins = {}
      for _, win in ipairs(wins) do
        if vim.api.nvim_win_is_valid(win) then
          local cfg = vim.api.nvim_win_get_config(win)
          if cfg.relative == '' then
            table.insert(real_wins, win)
          end
        end
      end
      for _, win in ipairs(real_wins) do
        pcall(function()
          if #real_wins > 1 then
            vim.wo[win].winbar = '  %t'
          else
            vim.wo[win].winbar = ''
          end
        end)
      end
    end)
  end,
})
vim.o.wrap = false            -- Disable line wrapping
vim.o.cursorline = false      -- Disable cursor line highlighting
vim.o.autoindent = true       -- Copy indent from current line when starting a new line
vim.opt.shortmess:append('s') -- Suppress "no lines in buffer" messages

-- Force 4-space indentation for Vue files and disable treesitter indent
vim.api.nvim_create_autocmd("FileType", {
  pattern = "vue",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
    vim.opt_local.indentexpr = ""
  end,
})


-- Remove all underline styling
vim.api.nvim_set_hl(0, "@lsp.type.function", {})
vim.api.nvim_set_hl(0, "@lsp.type.method", {})
vim.api.nvim_set_hl(0, "LspReferenceText", {})
vim.api.nvim_set_hl(0, "LspReferenceRead", {})
vim.api.nvim_set_hl(0, "LspReferenceWrite", {})

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- [[ Configure plugins ]]
-- NOTE: Here is where you install your plugins.
--  You can configure plugins using the `config` key.
--
--  You can also configure plugins after the setup call,
--    as they will be available in your neovim runtime.
require('lazy').setup({
  -- NOTE: First, some plugins that don't require any configuration

  -- Git related plugins
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  -- NOTE: This is where your plugins related to LSP can be installed.
  --  The configuration is done below. Search for lspconfig to find it below.
  {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      { 'williamboman/mason.nvim', config = true },
      'williamboman/mason-lspconfig.nvim',

      -- Useful status updates for LSP
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      {
        'j-hui/fidget.nvim',
        opts = {
          progress = {
            suppress_on_insert = true,
            ignore_done_already = true,
            ignore = { "ts_ls" },
          },
        },
      },

      -- Additional lua configuration, makes nvim stuff amazing!
      'folke/neodev.nvim',
    },
  },

  {
    -- Autocompletion
    'hrsh7th/nvim-cmp',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',

      -- Adds LSP completion capabilities
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',

      -- Adds a number of user-friendly snippets
      'rafamadriz/friendly-snippets',
    },
  },

  -- Useful plugin to show you pending keybinds.
  { 'folke/which-key.nvim',  opts = { delay = 500 } },
  {
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      -- See `:help gitsigns.txt`
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map({ 'n', 'v' }, ']c', function()
          if vim.wo.diff then
            return ']c'
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, desc = 'Jump to next hunk' })

        map({ 'n', 'v' }, '[c', function()
          if vim.wo.diff then
            return '[c'
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, desc = 'Jump to previous hunk' })

        -- Actions
        -- visual mode
        map('v', '<leader>hs', function()
          gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'stage git hunk' })
        map('v', '<leader>hr', function()
          gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'reset git hunk' })
        -- normal mode
        map('n', '<leader>hs', gs.stage_hunk, { desc = 'git stage hunk' })
        map('n', '<leader>hr', gs.reset_hunk, { desc = 'git reset hunk' })
        map('n', '<leader>hS', gs.stage_buffer, { desc = 'git Stage buffer' })
        map('n', '<leader>hu', gs.undo_stage_hunk, { desc = 'undo stage hunk' })
        map('n', '<leader>hR', gs.reset_buffer, { desc = 'git Reset buffer' })
        map('n', '<leader>hp', gs.preview_hunk, { desc = 'preview git hunk' })
        map('n', '<leader>hb', function()
          gs.blame_line { full = false }
        end, { desc = 'git blame line' })
        map('n', '<leader>hd', gs.diffthis, { desc = 'git diff against index' })
        map('n', '<leader>hD', function()
          gs.diffthis '~'
        end, { desc = 'git diff against last commit' })

        -- Toggles
        map('n', '<leader>tb', gs.toggle_current_line_blame, { desc = 'toggle git blame line' })
        map('n', '<leader>td', gs.toggle_deleted, { desc = 'toggle git show deleted' })

        -- Text object
        map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'select git hunk' })
      end,
    },
  },

  {
    'navarasu/onedark.nvim',
    priority = 1000,
    config = function()
      require('onedark').setup {
        style = 'dark',
        colors = {
          cyan = "#7aa2f7",   -- Softer blue instead of cyan
          orange = "#e5c07b", -- Softer orange (more yellow)
        },
        highlights = {
          ["@keyword"] = { fg = '$purple' },
          ["@function.builtin"] = { fg = '$blue' },
          ["@type.builtin"] = { fg = '$yellow' },
          ["String"] = { fg = '$green' },
          ["@string"] = { fg = '$green' },
          ["Comment"] = { fg = '#61AEEF' },
          ["@comment"] = { fg = '#61AEEF' },
          -- Remove all underlines
          ["@lsp.type.function"] = { fmt = 'none' },
          ["@lsp.type.method"] = { fmt = 'none' },
          ["@lsp.type.class"] = { fmt = 'none' },
          ["@lsp.type.namespace"] = { fmt = 'none' },
          ["@lsp.typemod.function.declaration"] = { fmt = 'none' },
          ["@lsp.typemod.method.declaration"] = { fmt = 'none' },
        },
      }
      require('onedark').load()
      -- Transparent statusline background
      vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })
    end,
  },

  {
    -- Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    -- See `:help lualine.txt`
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
          section_separators = { left = '\u{e0b0}', right = '\u{e0b2}' },
          globalstatus = true,
        },
        sections = {
          lualine_a = {
            'branch',
            { 'filetype', fmt = function(str)
              if str == 'php' then return 'PHP' end
              return str:sub(1, 1):upper() .. str:sub(2)
            end },
          },
          lualine_b = {},
          lualine_c = {},
          lualine_x = {},
          lualine_y = { 'diff' },
          lualine_z = { 'mode' },
        },
      }
    end,
  },

  {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    dependencies = { 'HiPhish/rainbow-delimiters.nvim' },
    config = function()
      local highlight = {
        "RainbowRed",
        "RainbowYellow",
        "RainbowBlue",
        "RainbowOrange",
        "RainbowGreen",
        "RainbowViolet",
        "RainbowCyan",
      }

      local hooks = require "ibl.hooks"
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
        vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
        vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
        vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
        vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
        vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
        vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#7aa2f7" })
        -- Clear tag name highlights so rainbow-delimiters colors the whole tag
        vim.api.nvim_set_hl(0, "@tag", {})
        vim.api.nvim_set_hl(0, "@tag.html", {})
        vim.api.nvim_set_hl(0, "@tag.vue", {})
        vim.api.nvim_set_hl(0, "@tag.delimiter", {})
        vim.api.nvim_set_hl(0, "@tag.delimiter.html", {})
        vim.api.nvim_set_hl(0, "@tag.delimiter.vue", {})
        vim.api.nvim_set_hl(0, "@punctuation.bracket", {})
        vim.api.nvim_set_hl(0, "@punctuation.bracket.vue", {})
      end)

      local rainbow = require('rainbow-delimiters')
      vim.g.rainbow_delimiters = {
        strategy = {
          [''] = rainbow.strategy['global'],
          html = rainbow.strategy['global'],
          vue = rainbow.strategy['global'],
          javascript = rainbow.strategy['global'],
          typescript = rainbow.strategy['global'],
          php = rainbow.strategy['global'],
        },
        query = {
          [''] = 'rainbow-delimiters',
          lua = 'rainbow-blocks',
        },
        highlight = highlight,
      }

      -- Refresh rainbow-delimiters on text changes
      vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        callback = function(args)
          local rd = require('rainbow-delimiters')
          if rd.is_enabled(args.buf) then
            rd.disable(args.buf)
            rd.enable(args.buf)
          end
        end,
      })

      require('ibl').setup {
        indent = { char = '│', highlight = "IblIndent" },
        scope = { enabled = true, highlight = highlight, show_start = false, show_end = false },
        exclude = { filetypes = { 'dashboard', 'alpha', 'starter' } },
      }

      -- Make default indent lines subtle gray
      vim.api.nvim_set_hl(0, "IblIndent", { fg = "#3e4452" })

      hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
    end,
  },

  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim', opts = {} },

  -- Fuzzy Finder (files, lsp, etc)
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      -- Fuzzy Finder Algorithm which requires local dependencies to be built.
      -- Only load if `make` is available. Make sure you have the system
      -- requirements installed.
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        -- NOTE: If you are having trouble with this installation,
        --       refer to the README for telescope-fzf-native for more instructions.
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
    },
  },

  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
  },

  {
    -- Auto-close and auto-rename HTML tags
    'windwp/nvim-ts-autotag',
    opts = {},
  },

  -- NOTE: Next Step on Your Neovim Journey: Add/Configure additional "plugins" for kickstart
  --       These are some example plugins that I've included in the kickstart repository.
  --       Uncomment any of the lines below to enable them.
  -- require 'kickstart.plugins.autoformat',
  -- require 'kickstart.plugins.debug',

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    You can use this folder to prevent any conflicts with this init.lua if you're interested in keeping
  --    up-to-date with whatever is in the kickstart repo.
  --    Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  --
  --    For additional information see: https://github.com/folke/lazy.nvim#-structuring-your-plugins
  { import = 'custom.plugins' },
}, {})

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.wo.number = true
vim.wo.relativenumber = true
vim.o.numberwidth = 1

-- Enable mouse mode
vim.o.mouse = 'a'

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = 'unnamedplus'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Disable sign column and fold column to remove padding
vim.wo.signcolumn = 'no'
vim.wo.foldcolumn = '0'

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Disable underlines in diagnostics
vim.diagnostic.config({
  underline = false,
})

-- Enable inlay hints by default, toggle with <leader>th
vim.lsp.inlay_hint.enable(true)
vim.keymap.set('n', '<leader>th', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = '[T]oggle inlay [H]ints' })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
      },
    },
  },
}

-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

-- Telescope live_grep in git root
-- Function to find the git root directory based on the current buffer's path
local function find_git_root()
  -- Use the current buffer's path as the starting point for the git search
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir
  local cwd = vim.fn.getcwd()
  -- If the buffer is not associated with a file, return nil
  if current_file == '' then
    current_dir = cwd
  else
    -- Extract the directory from the current file's path
    current_dir = vim.fn.fnamemodify(current_file, ':h')
  end

  -- Find the Git root directory from the current file's path
  local git_root = vim.fn.systemlist('git -C ' .. vim.fn.escape(current_dir, ' ') .. ' rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 then
    print 'Not a git repository. Searching on current working directory'
    return cwd
  end
  return git_root
end

-- Custom live_grep function to search in git root
local function live_grep_git_root()
  local git_root = find_git_root()
  if git_root then
    require('telescope.builtin').live_grep {
      search_dirs = { git_root },
    }
  end
end

vim.api.nvim_create_user_command('LiveGrepGitRoot', live_grep_git_root, {})

-- See `:help telescope.builtin`
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })

local function telescope_live_grep_open_files()
  require('telescope.builtin').live_grep {
    grep_open_files = true,
    prompt_title = 'Live Grep in Open Files',
  }
end
vim.keymap.set('n', '<leader>s/', telescope_live_grep_open_files, { desc = '[S]earch [/] in Open Files' })
vim.keymap.set('n', '<leader>ss', require('telescope.builtin').builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files, { desc = 'Search [G]it [F]iles' })
vim.keymap.set('n', '<leader>sf', function()
  require('telescope.builtin').find_files({ hidden = true })
end, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', function()
  require('telescope.builtin').live_grep({ cwd = vim.fn.getcwd() })
end, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sG', ':LiveGrepGitRoot<cr>', { desc = '[S]earch by [G]rep on Git Root' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', require('telescope.builtin').resume, { desc = '[S]earch [R]esume' })

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
-- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
vim.defer_fn(function()
  require('nvim-treesitter.configs').setup {
    -- Add languages to be installed here that you want installed for treesitter
    ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'rust', 'tsx', 'javascript', 'typescript', 'vimdoc', 'vim', 'bash', 'php', 'html', 'css', 'json', 'yaml', 'markdown', 'phpdoc', 'regex', 'vue' },

    -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
    auto_install = false,

    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<c-space>',
        node_incremental = '<c-space>',
        scope_incremental = '<c-s>',
        node_decremental = '<M-space>',
      },
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
          ['aa'] = '@parameter.outer',
          ['ia'] = '@parameter.inner',
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner',
        },
      },
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          [']m'] = '@function.outer',
          [']]'] = '@class.outer',
        },
        goto_next_end = {
          [']M'] = '@function.outer',
          [']['] = '@class.outer',
        },
        goto_previous_start = {
          ['[m'] = '@function.outer',
          ['[['] = '@class.outer',
        },
        goto_previous_end = {
          ['[M'] = '@function.outer',
          ['[]'] = '@class.outer',
        },
      },
      swap = {
        enable = true,
        swap_next = {
          ['<leader>a'] = '@parameter.inner',
        },
        swap_previous = {
          ['<leader>A'] = '@parameter.inner',
        },
      },
    },
  }
end, 0)

-- [[ Configure LSP ]]
--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(client, bufnr)
  -- Enable inlay hints (parameter hints like PhpStorm)
  vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })

  -- Toggle inlay hints with <leader>ih
  vim.keymap.set('n', '<leader>ih', function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
  end, { buffer = bufnr, desc = 'Toggle inlay hints' })

  -- Disable semantic token highlighting (removes underlines on current function)
  client.server_capabilities.semanticTokensProvider = nil

  -- NOTE: Remember that lua is a real programming language, and as such it is possible
  -- to define small helper and utility functions so you don't have to repeat yourself
  -- many times.
  --
  -- In this case, we create a function that lets us more easily define mappings specific
  -- for LSP related items. It sets the mode, buffer and description for us each time.
  local nmap = function(keys, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
  nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

  nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
  nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
  nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
  nmap('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
  nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
  nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

  -- See `:help K` for why this keymap
  nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
  nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

  -- Lesser used LSP functionality
  nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
  nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
  nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
  nmap('<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, '[W]orkspace [L]ist Folders')

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    vim.lsp.buf.format()
  end, { desc = 'Format current buffer with LSP' })
end

-- mason-lspconfig requires that these setup functions are called in this order
-- before setting up the servers.
require('mason').setup()
require('mason-lspconfig').setup()

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--
--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
--
--  If you want to override the default filetypes that your language server will attach to you can
--  define the property 'filetypes' to the map in question.
local servers = {
  -- clangd = {},
  -- gopls = {},
  -- pyright = {},
  -- rust_analyzer = {},
  -- html = { filetypes = { 'html', 'twig', 'hbs'} },


  intelephense = {
    filetypes = { 'php' },
    init_options = {
      licenceKey = "00EQQ3RLLHSB4FE",
      globalStoragePath = vim.fn.expand("~/Library/Application Support/intelephense"),
    },
    settings = {
      intelephense = {
        stubs = {
          "apache", "bcmath", "bz2", "calendar", "com_dotnet", "Core", "ctype", "curl",
          "date", "dba", "dom", "enchant", "exif", "FFI", "fileinfo", "filter", "fpm",
          "ftp", "gd", "gettext", "gmp", "hash", "iconv", "imap", "intl", "json",
          "ldap", "libxml", "mbstring", "meta", "mysqli", "oci8", "odbc", "openssl",
          "pcntl", "pcre", "PDO", "pdo_ibm", "pdo_mysql", "pdo_pgsql", "pdo_sqlite",
          "pgsql", "Phar", "posix", "pspell", "readline", "Reflection", "session",
          "shmop", "SimpleXML", "snmp", "soap", "sockets", "sodium", "SPL", "sqlite3",
          "standard", "superglobals", "sysvmsg", "sysvsem", "sysvshm", "tidy", "tokenizer",
          "xml", "xmlreader", "xmlrpc", "xmlwriter", "xsl", "Zend OPcache", "zip", "zlib",
          "wordpress", "phpunit",
        },
        files = {
          maxSize = 5000000,
        },
        environment = {
          includePaths = {},
        },
        licenceKey = "00EQQ3RLLHSB4FE",
        inlayHints = {
          parameterNames = {
            enabled = "all",
          },
          parameterTypes = {
            enabled = true,
          },
          variableTypes = {
            enabled = true,
          },
          propertyDeclarationTypes = {
            enabled = true,
          },
          functionReturnTypes = {
            enabled = true,
          },
        },
      },
    },
  },

  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
      -- NOTE: toggle below to ignore Lua_LS's noisy `missing-fields` warnings
      -- diagnostics = { disable = { 'missing-fields' } },
    },
  },
}

-- Setup neovim lua configuration
require('neodev').setup()

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Ensure the servers above are installed
local mason_lspconfig = require 'mason-lspconfig'

mason_lspconfig.setup {
  ensure_installed = vim.tbl_keys(servers),
  handlers = {
    function(server_name)
      if server_name == "intelephense" then return end -- Skip, configured below
      local server_config = servers[server_name] or {}
      require('lspconfig')[server_name].setup {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = server_config.settings or server_config,
        filetypes = server_config.filetypes,
        init_options = server_config.init_options,
      }
    end,
  },
}

-- Configure intelephense separately with license (nvim 0.11+ API)
local intelephense_licence_path = vim.fn.expand("~/Library/Application Support/intelephense/licence.txt")
local intelephense_licence_key = nil
if vim.fn.filereadable(intelephense_licence_path) == 1 then
  intelephense_licence_key = vim.fn.readfile(intelephense_licence_path)[1]
end

vim.lsp.config.intelephense = {
  cmd = { 'intelephense', '--stdio' },
  filetypes = { 'php' },
  root_markers = { 'composer.json', '.git' },
  init_options = {
    licenceKey = intelephense_licence_key,
    globalStoragePath = vim.fn.expand("~/Library/Application Support/intelephense"),
  },
  settings = servers.intelephense.settings,
}
vim.lsp.enable('intelephense')

-- Configure Vue + TypeScript (nvim 0.11+ API)
local vue_language_server_path = vim.fn.expand(
  '~/.local/share/nvim/mason/packages/vue-language-server/node_modules/@vue/language-server')

local vue_plugin = {
  name = '@vue/typescript-plugin',
  location = vue_language_server_path,
  languages = { 'vue' },
}

vim.lsp.config.ts_ls = {
  init_options = {
    plugins = { vue_plugin },
  },
  filetypes = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'vue' },
}
vim.lsp.enable('ts_ls')

vim.lsp.config.vue_ls = {
  cmd = { 'vue-language-server', '--stdio' },
  filetypes = { 'vue' },
  root_markers = { 'package.json', '.git' },
}
vim.lsp.enable('vue_ls')

-- [[ Configure nvim-cmp ]]
-- See `:help cmp`
local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
require('luasnip.loaders.from_vscode').lazy_load({ paths = { vim.fn.stdpath('config') .. '/snippets' } })
luasnip.config.setup {}

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  completion = {
    completeopt = 'menu,menuone,noinsert',
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete {},
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'nvim_lsp', max_item_count = 5 },
    { name = 'luasnip',  max_item_count = 3 },
    { name = 'path',     max_item_count = 3 },
  },
}

vim.opt.hlsearch = true

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("i", "jj", "<ESC>")

vim.keymap.set("i", ";;", "<Esc>A;<Esc>")
vim.keymap.set("i", ",,", "<Esc>A,<Esc>")

-- Neo-tree
vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Toggle file tree" })

-- Close buffer without saving
vim.keymap.set("n", "<leader>x", "<cmd>bd!<cr>", { desc = "Close buffer (force)" })

-- Close split/window
vim.keymap.set("n", "<leader>w", "<cmd>close<cr>", { desc = "Close split" })

-- Save file
vim.keymap.set("n", "<leader>s", "<cmd>w<cr>", { desc = "Save file" })

-- New vertical split with empty buffer (opens on right) and open Telescope
vim.keymap.set("n", "<leader>v", function()
  vim.cmd('rightbelow vnew')
  require('telescope.builtin').find_files({ hidden = true })
end, { desc = "New vertical split" })


-- Auto-indent when pressing i on an empty line
vim.keymap.set("n", "i", function()
  if vim.fn.getline('.') == '' then
    return '"_cc'
  else
    return 'i'
  end
end, { expr = true, noremap = true })

-- Move to next line and auto-indent if it's blank, otherwise normal o
vim.keymap.set("n", "o", function()
  local next_line = vim.fn.getline(vim.fn.line('.') + 1)
  if next_line == '' then
    return 'j"_cc'
  else
    return 'o'
  end
end, { expr = true, noremap = true })

-- Move to previous line and auto-indent if it's blank, otherwise normal O
vim.keymap.set("n", "O", function()
  local prev_line = vim.fn.getline(vim.fn.line('.') - 1)
  if prev_line == '' then
    return 'k"_cc'
  else
    return 'O'
  end
end, { expr = true, noremap = true })

-- Move to first non-blank after j/k (and arrow keys)
vim.keymap.set('n', 'j', 'j_', { noremap = true, silent = true })
vim.keymap.set('n', 'k', 'k_', { noremap = true, silent = true })
vim.keymap.set('n', '<Down>', 'j_', { noremap = true, silent = true })
vim.keymap.set('n', '<Up>', 'k_', { noremap = true, silent = true })

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
