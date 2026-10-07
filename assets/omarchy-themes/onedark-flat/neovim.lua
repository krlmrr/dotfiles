return {
  {
    "navarasu/onedark.nvim",
    name = "onedark",
    priority = 1000,
    opts = {
      style = "dark",
      colors = {
        fg = "#dcdfe4",
        bg1 = "#313640",
        bg3 = "#474e5d",
        light_grey = "#919baa",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "onedark",
    },
  },
}
