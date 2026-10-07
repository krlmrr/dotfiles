return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections.lualine_z = {
      function()
        return " " .. os.date("!%R") .. " UTC"
      end,
    }
  end,
}
