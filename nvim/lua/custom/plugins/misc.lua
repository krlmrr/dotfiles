-- Simple plugins that don't need their own file
return {
  -- Detect tabstop and shiftwidth automatically
  {
    'nmac427/guess-indent.nvim',
    opts = {},
  },

  -- Show pending keybinds
  { 'folke/which-key.nvim',   opts = { delay = 150 } },

  -- Comment with gc
  { 'numToStr/Comment.nvim',  opts = {} },

  -- Auto-close HTML tags
  { 'windwp/nvim-ts-autotag', opts = {} },
}
