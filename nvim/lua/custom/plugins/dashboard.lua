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
                    '',
                    '⟨ karlm ⟩',
                    '',
                },
                shortcut = {
                    { desc = ' Find',   group = 'DashboardShortCut', action = 'Telescope find_files', key = 'f' },
                    { desc = ' Recent', group = 'DashboardShortCut', action = 'Telescope oldfiles',   key = 'r' },
                    { desc = ' Grep',   group = 'DashboardShortCut', action = 'Telescope live_grep',  key = 'g' },
                    { desc = ' Quit',   group = 'DashboardShortCut', action = 'quit',                 key = 'q' },
                },
                packages = { enable = false },
                project = { enable = false },
                mru = { limit = 5, cwd_only = true },
                footer = {},
            },
        })

        -- Hide cursor, show only cursorline on dashboard (after setup)
        vim.api.nvim_create_autocmd('FileType', {
            pattern = 'dashboard',
            callback = function()
                -- Close neo-tree if open (only if already loaded)
                vim.schedule(function()
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        local buf = vim.api.nvim_win_get_buf(win)
                        if vim.bo[buf].filetype == 'neo-tree' then
                            pcall(vim.api.nvim_win_close, win, true)
                        end
                    end
                end)
                -- Disable <leader>e on dashboard
                vim.keymap.set('n', '<leader>e', '<Nop>', { buffer = true, silent = true })

                vim.defer_fn(function()
                    vim.cmd('highlight Cursor blend=100')
                    vim.opt.guicursor:append('a:Cursor/lCursor')
                    vim.cmd('highlight CursorLine guibg=#3e4452')
                    vim.opt_local.cursorline = true
                    vim.wo.cursorlineopt = 'line'

                    local bufnr = vim.api.nvim_get_current_buf()
                    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

                    -- Find shortcuts line by content (reliable anchor point)
                    local shortcuts_line = nil
                    for i, line in ipairs(lines) do
                        if line:match('Find') and line:match('Quit') then
                            shortcuts_line = i - 1  -- 0-indexed
                            break
                        end
                    end
                    if not shortcuts_line then return end

                    -- Get dashboard namespace
                    local ns = nil
                    for name, id in pairs(vim.api.nvim_get_namespaces()) do
                        if name:match('dashboard') then
                            ns = id
                            break
                        end
                    end
                    if not ns then return end

                    -- Find MRU file lines (extmarks with virt_text AFTER shortcuts line)
                    local min_line = nil
                    local max_line = nil
                    for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true })) do
                        local line = mark[2]
                        if mark[4].virt_text and line > shortcuts_line then
                            if not min_line then
                                min_line = line
                            else
                                min_line = math.min(min_line, line)
                            end
                            max_line = max_line and math.max(max_line, line) or line
                        end
                    end
                    -- Fallback if no MRU files found
                    if not min_line then min_line = shortcuts_line end
                    if not max_line then max_line = shortcuts_line end

                    -- If no MRU files, show cursorline on "empty files" and lock cursor
                    if max_line == min_line then
                        local empty_line = nil
                        for i, line in ipairs(lines) do
                            if line:match('empty') then
                                empty_line = i
                                break
                            end
                        end
                        if empty_line then
                            vim.api.nvim_win_set_cursor(0, { empty_line, 0 })
                            -- Block all cursor movement
                            local opts = { buffer = bufnr, nowait = true, silent = true }
                            vim.keymap.set('n', 'j', '<Nop>', opts)
                            vim.keymap.set('n', 'k', '<Nop>', opts)
                            vim.keymap.set('n', '<Down>', '<Nop>', opts)
                            vim.keymap.set('n', '<Up>', '<Nop>', opts)
                            vim.keymap.set('n', 'gg', '<Nop>', opts)
                            vim.keymap.set('n', 'G', '<Nop>', opts)
                        end
                        return
                    end

                    -- Highlight groups for shortcut keys
                    vim.cmd('highlight DashboardShortCut guifg=#61afef guibg=NONE')
                    vim.cmd('highlight DashboardShortCutCursor guifg=#61afef guibg=#3e4452')

                    local function update_shortcuts()
                        local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1
                        -- Clamp cursor
                        if cursor_line < min_line then
                            vim.api.nvim_win_set_cursor(0, { min_line + 1, 0 })
                            cursor_line = min_line
                        elseif cursor_line > max_line then
                            vim.api.nvim_win_set_cursor(0, { max_line + 1, 0 })
                            cursor_line = max_line
                        end
                        -- Update shortcut highlights (only for marks at shortcuts_line or after)
                        for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true })) do
                            local line = mark[2]
                            local details = mark[4]
                            if details.virt_text and line >= shortcuts_line then
                                local hl = line == cursor_line and 'DashboardShortCutCursor' or 'DashboardShortCut'
                                vim.api.nvim_buf_set_extmark(bufnr, ns, line, mark[3], {
                                    id = mark[1],
                                    virt_text = { { details.virt_text[1][1], hl } },
                                    virt_text_pos = details.virt_text_pos,
                                })
                            end
                        end
                    end

                    -- Set initial cursor position and highlights
                    vim.api.nvim_win_set_cursor(0, { min_line + 1, 0 })
                    update_shortcuts()

                    vim.api.nvim_create_autocmd('CursorMoved', {
                        buffer = bufnr,
                        callback = update_shortcuts,
                    })
                end, 50)
            end,
        })
        -- Restore cursor when leaving dashboard
        vim.api.nvim_create_autocmd('FileType', {
            pattern = '*',
            callback = function()
                if vim.bo.filetype ~= 'dashboard' and vim.bo.filetype ~= 'neo-tree' then
                    vim.cmd('highlight Cursor blend=0')
                end
            end,
        })
    end,
}
