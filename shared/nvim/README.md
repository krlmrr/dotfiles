# Neovim Configuration

A Kickstart-based Neovim configuration optimized for PHP/Laravel development.

## Structure

```
nvim/
├── init.lua                 # Main configuration file
├── lazy-lock.json           # Plugin version lockfile
└── lua/
    ├── kickstart/
    │   └── plugins/         # Optional kickstart modules
    │       ├── autoformat.lua
    │       └── debug.lua
    └── custom/
        └── plugins/         # Custom plugins (auto-loaded)
            ├── init.lua
            ├── autopairs.lua
            ├── blade.lua
            ├── conform.lua
            ├── neo-tree.lua
            └── noice.lua
```

## Plugins

### Core

| Plugin | Description |
|--------|-------------|
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Plugin manager |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP configuration |
| [mason.nvim](https://github.com/williamboman/mason.nvim) | LSP/DAP/Linter installer |
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | Autocompletion |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | Snippet engine |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax highlighting & code understanding |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder |

### Git

| Plugin | Description |
|--------|-------------|
| [vim-fugitive](https://github.com/tpope/vim-fugitive) | Git commands (`:Git`, `:Gblame`, etc.) |
| [vim-rhubarb](https://github.com/tpope/vim-rhubarb) | GitHub integration for fugitive |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git signs in gutter, hunk actions |

### UI

| Plugin | Description |
|--------|-------------|
| [onedark.nvim](https://github.com/navarasu/onedark.nvim) | Colorscheme |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Statusline |
| [indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim) | Indentation guides |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Keybinding hints |
| [fidget.nvim](https://github.com/j-hui/fidget.nvim) | LSP progress indicator |
| [noice.nvim](https://github.com/folke/noice.nvim) | Modern UI for messages, cmdline, popupmenu |
| [nvim-notify](https://github.com/rcarriga/nvim-notify) | Fancy notification popups |

### Editing

| Plugin | Description |
|--------|-------------|
| [Comment.nvim](https://github.com/numToStr/Comment.nvim) | Toggle comments with `gc` |
| [nvim-autopairs](https://github.com/windwp/nvim-autopairs) | Auto-close brackets, quotes |
| [vim-sleuth](https://github.com/tpope/vim-sleuth) | Auto-detect indent settings |
| [conform.nvim](https://github.com/stevearc/conform.nvim) | Code formatting |

### File Navigation

| Plugin | Description |
|--------|-------------|
| [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) | File tree sidebar |

### PHP/Laravel

| Plugin | Description |
|--------|-------------|
| [tree-sitter-blade](https://github.com/EmranMR/tree-sitter-blade) | Blade template syntax highlighting |
| intelephense (via Mason) | PHP language server |

## Language Servers

Configured in `init.lua` under the `servers` table:

| Server | Language | Notes |
|--------|----------|-------|
| `intelephense` | PHP | Full Laravel support, includes common stubs |
| `lua_ls` | Lua | For editing Neovim config |

Install via Mason: `:MasonInstall intelephense lua_ls`

## Keyboard Shortcuts

**Leader key: `Space`**

### General

| Key | Mode | Description |
|-----|------|-------------|
| `jj` | Insert | Exit insert mode (same as `<Esc>`) |
| `;;` | Insert | Add semicolon at end of line |
| `,,` | Insert | Add comma at end of line |
| `<Esc>` | Normal | Clear search highlight |
| `gc` | Normal/Visual | Toggle comment |
| `gcc` | Normal | Toggle comment on line |

### File Navigation

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>e` | Normal | Toggle Neo-tree (right side) |
| `<leader>sf` | Normal | Search files |
| `<leader>gf` | Normal | Search git files |
| `<leader>?` | Normal | Find recently opened files |
| `<leader><space>` | Normal | Find open buffers |

### Search (Telescope)

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>/` | Normal | Fuzzy search in current buffer |
| `<leader>s/` | Normal | Search in open files |
| `<leader>sg` | Normal | Live grep (search text) |
| `<leader>sG` | Normal | Live grep from git root |
| `<leader>sw` | Normal | Search current word |
| `<leader>sd` | Normal | Search diagnostics |
| `<leader>sh` | Normal | Search help tags |
| `<leader>ss` | Normal | Search Telescope builtins |
| `<leader>sr` | Normal | Resume last search |

### LSP (when attached)

| Key | Mode | Description |
|-----|------|-------------|
| `gd` | Normal | Go to definition |
| `gD` | Normal | Go to declaration |
| `gr` | Normal | Go to references |
| `gI` | Normal | Go to implementation |
| `K` | Normal | Hover documentation |
| `<C-k>` | Normal | Signature help |
| `<leader>rn` | Normal | Rename symbol |
| `<leader>ca` | Normal | Code action |
| `<leader>D` | Normal | Type definition |
| `<leader>ds` | Normal | Document symbols |
| `<leader>ws` | Normal | Workspace symbols |
| `<leader>wa` | Normal | Add workspace folder |
| `<leader>wr` | Normal | Remove workspace folder |
| `<leader>wl` | Normal | List workspace folders |
| `:Format` | Command | Format current buffer |

### Diagnostics

| Key | Mode | Description |
|-----|------|-------------|
| `[d` | Normal | Previous diagnostic |
| `]d` | Normal | Next diagnostic |
| `<leader>e` | Normal | Open diagnostic float |
| `<leader>q` | Normal | Open diagnostics list |

### Git (Gitsigns)

| Key | Mode | Description |
|-----|------|-------------|
| `]c` | Normal | Next git hunk |
| `[c` | Normal | Previous git hunk |
| `<leader>hs` | Normal/Visual | Stage hunk |
| `<leader>hr` | Normal/Visual | Reset hunk |
| `<leader>hS` | Normal | Stage buffer |
| `<leader>hu` | Normal | Undo stage hunk |
| `<leader>hR` | Normal | Reset buffer |
| `<leader>hp` | Normal | Preview hunk |
| `<leader>hb` | Normal | Blame line |
| `<leader>hd` | Normal | Diff against index |
| `<leader>hD` | Normal | Diff against last commit |
| `<leader>tb` | Normal | Toggle line blame |
| `<leader>td` | Normal | Toggle show deleted |
| `ih` | Operator/Visual | Select git hunk (text object) |

### Treesitter Text Objects

| Key | Mode | Description |
|-----|------|-------------|
| `af` | Operator/Visual | Select around function |
| `if` | Operator/Visual | Select inside function |
| `ac` | Operator/Visual | Select around class |
| `ic` | Operator/Visual | Select inside class |
| `aa` | Operator/Visual | Select around parameter |
| `ia` | Operator/Visual | Select inside parameter |

### Treesitter Navigation

| Key | Mode | Description |
|-----|------|-------------|
| `]m` | Normal | Next function start |
| `]M` | Normal | Next function end |
| `]]` | Normal | Next class start |
| `][` | Normal | Next class end |
| `[m` | Normal | Previous function start |
| `[M` | Normal | Previous function end |
| `[[` | Normal | Previous class start |
| `[]` | Normal | Previous class end |

### Treesitter Selection

| Key | Mode | Description |
|-----|------|-------------|
| `<C-space>` | Normal/Visual | Init/expand selection |
| `<C-s>` | Visual | Expand to scope |
| `<M-space>` | Visual | Shrink selection |

### Treesitter Swap

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>a` | Normal | Swap parameter with next |
| `<leader>A` | Normal | Swap parameter with previous |

### Completion (nvim-cmp)

| Key | Mode | Description |
|-----|------|-------------|
| `<C-n>` | Insert | Next completion item |
| `<C-p>` | Insert | Previous completion item |
| `<Tab>` | Insert | Next item / expand snippet |
| `<S-Tab>` | Insert | Previous item |
| `<CR>` | Insert | Confirm completion |
| `<C-Space>` | Insert | Trigger completion |
| `<C-b>` | Insert | Scroll docs up |
| `<C-f>` | Insert | Scroll docs down |

## Formatting

Auto-format on save is enabled via conform.nvim:

| Filetype | Formatter |
|----------|-----------|
| PHP | `pint` (Laravel Pint via `vendor/bin/pint`) |
| Blade | `blade-formatter` |
| Lua | `stylua` |
| JavaScript/TypeScript | `prettier` |
| XML | `xmlformat` |

## Setup

1. **Symlink config** (already done):
   ```bash
   ln -s ~/code/dotfiles/nvim ~/.config/nvim
   ```

2. **Open Neovim** - lazy.nvim will auto-install plugins:
   ```bash
   nvim
   ```

3. **Install language servers**:
   ```vim
   :MasonInstall intelephense lua_ls
   ```

4. **Install treesitter parsers**:
   ```vim
   :TSUpdate
   :TSInstall blade
   ```

5. **Install formatters** (optional):
   ```bash
   # For Blade formatting
   npm install -g blade-formatter

   # For Lua formatting
   brew install stylua
   ```

## Options

Key options set in `init.lua`:

| Option | Value | Description |
|--------|-------|-------------|
| `tabstop` | 4 | Tab displays as 4 spaces |
| `expandtab` | true | Use spaces instead of tabs |
| `shiftwidth` | 4 | Indent by 4 spaces |
| `number` | true | Show line numbers |
| `relativenumber` | true | Relative line numbers |
| `mouse` | 'a' | Enable mouse in all modes |
| `clipboard` | 'unnamedplus' | Use system clipboard |
| `undofile` | true | Persistent undo history |
| `ignorecase` | true | Case-insensitive search |
| `smartcase` | true | ...unless search has capitals |
| `termguicolors` | true | True color support |
| `updatetime` | 250 | Faster CursorHold events |
| `timeoutlen` | 300 | Faster which-key popup |
| `globalstatus` | true | Single statusline across all windows |

## Commands

| Command | Description |
|---------|-------------|
| `:Lazy` | Open plugin manager |
| `:Mason` | Open LSP/tool installer |
| `:Format` | Format current buffer |
| `:Neotree` | Open file tree |
| `:TSUpdate` | Update treesitter parsers |
| `:checkhealth` | Check Neovim health |
