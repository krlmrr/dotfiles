-- Floating terminal with state preservation
local terminal = {
  buf = nil,
  win = nil,
}

-- Set up highlight groups for floating terminal
local function set_highlights()
  vim.api.nvim_set_hl(0, 'FloatTermBorder', { fg = '#61afef', bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'FloatTermNormal', { bg = 'NONE' })
end

-- Apply highlights now and after any colorscheme change
set_highlights()
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = set_highlights,
})

local function create_float_win(buf)
  local width = vim.o.columns
  local height = vim.o.lines - 4  -- Account for cmdline/statusline
  local row = math.floor((vim.o.lines - height) / 2) - 1
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })

  -- Set window options
  vim.wo[win].winblend = 0
  vim.wo[win].winhighlight = 'Normal:FloatTermNormal,FloatBorder:FloatTermBorder'

  return win
end

local function toggle_terminal()
  -- If window exists and is valid, close it
  if terminal.win and vim.api.nvim_win_is_valid(terminal.win) then
    vim.api.nvim_win_close(terminal.win, true)
    terminal.win = nil
    return
  end

  -- If buffer doesn't exist or is invalid, create new one
  if not terminal.buf or not vim.api.nvim_buf_is_valid(terminal.buf) then
    terminal.buf = vim.api.nvim_create_buf(false, true)
    -- Open terminal in the buffer
    vim.api.nvim_buf_call(terminal.buf, function()
      vim.fn.termopen(vim.o.shell, { cwd = vim.fn.getcwd() })
    end)
  end

  -- Create floating window
  terminal.win = create_float_win(terminal.buf)

  -- Enter insert mode
  vim.cmd('startinsert')
end

local function reset_terminal()
  -- Close window if open
  if terminal.win and vim.api.nvim_win_is_valid(terminal.win) then
    vim.api.nvim_win_close(terminal.win, true)
    terminal.win = nil
  end
  -- Delete buffer if exists
  if terminal.buf and vim.api.nvim_buf_is_valid(terminal.buf) then
    vim.api.nvim_buf_delete(terminal.buf, { force = true })
  end
  terminal.buf = nil
  -- Open fresh terminal
  toggle_terminal()
end

-- Set up keymaps
vim.keymap.set({ 'n', 't' }, '<leader>tt', toggle_terminal, { desc = 'Toggle floating terminal' })
vim.keymap.set({ 'n', 't' }, '<leader>tr', reset_terminal, { desc = 'Reset floating terminal' })

-- Close terminal with Escape when in terminal mode inside float
vim.api.nvim_create_autocmd('TermOpen', {
  pattern = '*',
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    -- Map Escape to toggle off (only for our floating terminal)
    vim.keymap.set('t', '<Esc>', function()
      if terminal.buf == buf and terminal.win and vim.api.nvim_win_is_valid(terminal.win) then
        toggle_terminal()
      else
        -- Default behavior for other terminals
        return '<C-\\><C-n>'
      end
    end, { buffer = buf, expr = false, desc = 'Close floating terminal or exit term mode' })
  end,
})

return {}
