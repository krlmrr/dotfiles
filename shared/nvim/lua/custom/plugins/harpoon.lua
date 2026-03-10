return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require('harpoon')
    harpoon:setup({
      settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
      },
    })

    -- Harpoon highlight groups
    vim.api.nvim_set_hl(0, "HarpoonBorder", { fg = "#7AA2F7", bg = "NONE" })
    vim.api.nvim_set_hl(0, "HarpoonTitle", { fg = "#7AA2F7", bg = "NONE" })
    vim.api.nvim_set_hl(0, "HarpoonWindow", { fg = "#abb2bf", bg = "NONE" })

    -- Style the harpoon menu
    harpoon:extend({
      UI_CREATE = function(cx)
        local win = cx.win_id
        vim.api.nvim_set_option_value('winhighlight', 'Normal:HarpoonWindow,FloatBorder:HarpoonBorder,FloatTitle:HarpoonTitle', { win = win })
        vim.api.nvim_win_set_config(win, {
          border = 'rounded',
        })
      end,
    })

    vim.keymap.set('n', '<leader>m', function()
      harpoon:list():add()
      vim.notify('Added to Harpoon', vim.log.levels.INFO)
    end, { desc = 'Harpoon mark file' })
    vim.keymap.set('n', '<leader>h', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon menu' })
    vim.keymap.set('n', '<leader>1', function() harpoon:list():select(1) end, { desc = 'Harpoon file 1' })
    vim.keymap.set('n', '<leader>2', function() harpoon:list():select(2) end, { desc = 'Harpoon file 2' })
    vim.keymap.set('n', '<leader>3', function() harpoon:list():select(3) end, { desc = 'Harpoon file 3' })
    vim.keymap.set('n', '<leader>4', function() harpoon:list():select(4) end, { desc = 'Harpoon file 4' })
    vim.keymap.set('n', '<leader>5', function() harpoon:list():select(5) end, { desc = 'Harpoon file 5' })
  end,
}
