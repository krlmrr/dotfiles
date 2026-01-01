-- Simple plugins that don't need their own file
return {
  -- Detect tabstop and shiftwidth automatically
  {
    'nmac427/guess-indent.nvim',
    opts = {},
  },

  -- Show pending keybinds
  {
    'folke/which-key.nvim',
    opts = { delay = 150 },
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      wk.add({
        -- Common vim motions cheatsheet
        { "d", group = "delete" },
        { "dw", desc = "delete word" },
        { "de", desc = "delete to end of word" },
        { "db", desc = "delete back word" },
        { "dd", desc = "delete line" },
        { "D", desc = "delete to end of line" },
        { "d$", desc = "delete to end of line" },
        { "d0", desc = "delete to start of line" },
        { "dt", desc = "delete to (char)" },
        { "df", desc = "delete through (char)" },
        { "di", group = "delete inside" },
        { "da", group = "delete around" },
        { "c", group = "change" },
        { "cw", desc = "change word" },
        { "ce", desc = "change to end of word" },
        { "cc", desc = "change line" },
        { "C", desc = "change to end of line" },
        { "ci", group = "change inside" },
        { "ca", group = "change around" },
        { "y", group = "yank (copy)" },
        { "yw", desc = "yank word" },
        { "yy", desc = "yank line" },
        { "Y", desc = "yank to end of line" },
        { "yi", group = "yank inside" },
        { "ya", group = "yank around" },
        { "g", group = "goto/misc" },
        { "gg", desc = "go to first line" },
        { "G", desc = "go to last line" },
        { "gd", desc = "go to definition" },
        { "gr", desc = "go to references" },
        { "z", group = "folds/view" },
        { "za", desc = "toggle fold" },
        { "zc", desc = "close fold" },
        { "zo", desc = "open fold" },
        { "zz", desc = "center cursor" },
      })
    end,
  },

  -- Comment with gc
  { 'numToStr/Comment.nvim',  opts = {} },

  -- Auto-close HTML tags
  { 'windwp/nvim-ts-autotag', opts = {} },
}
