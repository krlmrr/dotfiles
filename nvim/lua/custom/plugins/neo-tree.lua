-- Unless you are still migrating, remove the deprecated commands from v1.x
vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])

return {
  'nvim-neo-tree/neo-tree.nvim',
  cmd = 'Neotree',
  keys = {
    { '<leader>n', ':Neotree toggle<CR>' },
    { '<leader>N', ':Neotree focus<CR>' },
  },
  version = "*",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require('neo-tree').setup {
      popup_border_style = "rounded",
      default_component_configs = {
        filesystem = {
          follow_current_file = {
            enabled = false,         -- This will find and focus the file in the active buffer every time
            --               -- the current file is changed while the tree is open.
            leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
          },
        }
      }
    }
  end,
}
