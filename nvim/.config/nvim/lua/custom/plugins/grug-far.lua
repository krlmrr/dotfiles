return {
  'MagicDuck/grug-far.nvim',
  cmd = 'GrugFar',
  keys = {
    {
      '<leader>S',
      function() require('grug-far').open() end,
      desc = 'Search and replace',
    },
    {
      '<leader>sp',
      function()
        require('grug-far').open { prefills = { paths = vim.fn.expand('%') } }
      end,
      desc = 'Search and replace in current file',
    },
    {
      '<leader>sw',
      mode = 'v',
      function()
        require('grug-far').open { visualSelectionUsage = 'operate-within-range' }
      end,
      desc = 'Search and replace in selection',
    },
  },
  opts = {},
}
