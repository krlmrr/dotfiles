-- Simple plugins that don't need their own file
return {
  -- Git related plugins
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  -- Show pending keybinds
  { 'folke/which-key.nvim', opts = { delay = 150 } },

  -- Comment with gc
  { 'numToStr/Comment.nvim', opts = {} },

  -- Auto-close HTML tags
  { 'windwp/nvim-ts-autotag', opts = {} },
}
