return {
  'navarasu/onedark.nvim',
  priority = 1000,
  dependencies = { "catppuccin/nvim" },
  config = function()
    -- Apply theme based on system appearance
    require('config.theme').apply()

    -- Sync theme when Neovim gains focus (detects system theme changes)
    vim.api.nvim_create_autocmd("FocusGained", {
      callback = function()
        require('config.theme').sync()
      end,
    })

    -- Add command to manually toggle theme
    vim.api.nvim_create_user_command("ToggleTheme", function()
      require('config.theme').toggle()
    end, { desc = "Toggle between light and dark theme" })
  end,
}
