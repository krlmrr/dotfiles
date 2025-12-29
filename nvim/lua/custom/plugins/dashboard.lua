return {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require('dashboard').setup({
            theme = 'hyper',
            config = {
                week_header = { enable = false },
                header = {
                    '',
                    ' ⟨ neovim ⟩ ',
                    '',
                },
                shortcut = {
                    { desc = ' Find', group = 'DashboardShortCut', action = 'Telescope find_files', key = 'f' },
                    { desc = ' Recent', group = 'DashboardShortCut', action = 'Telescope oldfiles', key = 'r' },
                    { desc = ' Grep', group = 'DashboardShortCut', action = 'Telescope live_grep', key = 'g' },
                    { desc = ' Quit', group = 'DashboardShortCut', action = 'quit', key = 'q' },
                },
                packages = { enable = false },
                project = { enable = false },
                mru = { limit = 5, cwd_only = true },
                footer = {},
            },
        })
    end,
}
