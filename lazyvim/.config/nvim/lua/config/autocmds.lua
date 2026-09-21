-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Keep at most 5 buffers of a given filetype open, closing the oldest first.
local max_buffers = 5

local function trim_old_buffers(buf)
  local scope = vim.bo[buf].filetype ~= "" and vim.bo[buf].filetype or "plain"
  local windows = vim.api.nvim_list_wins()
  local bufs = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b)
      and vim.bo[b].buflisted
      and not vim.bo[b].modified
      and vim.fn.bufname(b) ~= ""
      and b ~= buf
    then
      local bt = vim.bo[b].filetype == "" and "plain" or vim.bo[b].filetype
      if bt == scope then
        table.insert(bufs, { buf = b, last = vim.fn.getbufinfo(b)[1].lastused })
      end
    end
  end

  table.sort(bufs, function(a, b)
    return a.last < b.last
  end)

  local now_open = vim.bo[buf].buflisted
  local count = (now_open and 1 or 0) + #bufs
  for _, item in ipairs(bufs) do
    if count <= max_buffers then
      break
    end
    -- don't close a buffer open in a window
    local in_win = false
    for _, w in ipairs(windows) do
      if vim.api.nvim_win_get_buf(w) == item.buf then
        in_win = true
        break
      end
    end
    if not in_win then
      pcall(vim.api.nvim_buf_delete, item.buf, { force = false })
      count = count - 1
    end
  end
end

vim.api.nvim_create_autocmd({ "BufNew", "BufAdd" }, {
  callback = function(args)
    if vim.bo[args.buf].buflisted then
      trim_old_buffers(args.buf)
    end
  end,
})

-- Remove a leftover unnamed [No Name] buffer once a real file is opened.
-- Fires on BufEnter when we land in a named (real file) buffer. It deletes any
-- unnamed, empty, unmodified buffer that is NOT shown in any window — so the
-- dashboard/sidebar taking focus never triggers it, and an intentional :enew
-- you're currently viewing survives. Restart nvim to apply.
local buf_session = vim.api.nvim_create_augroup("lerd_remove_nameless", { clear = true })

vim.api.nvim_create_autocmd("BufEnter", {
  group = buf_session,
  callback = function(args)
    local cur = args.buf
    -- only run when we've actually entered a real file
    if vim.fn.bufname(cur) == "" then
      return
    end
    local wins = vim.api.nvim_list_wins()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if b ~= cur
        and vim.api.nvim_buf_is_valid(b)
        and vim.bo[b].buflisted
        and vim.bo[b].modified == false
        and vim.bo[b].buftype == ""
        and vim.fn.bufname(b) == ""
      then
        -- skip if it's still visible in some window
        local visible = false
        for _, w in ipairs(wins) do
          if vim.api.nvim_win_get_buf(w) == b then
            visible = true
            break
          end
        end
        if not visible then
          pcall(vim.api.nvim_buf_delete, b, { force = false })
        end
      end
    end
  end,
})

-- Reload buffers changed outside nvim.
-- LazyVim only runs checktime on FocusGained, TermClose and TermLeave, so a file
-- rewritten by something else while you sit in the buffer goes unnoticed until you
-- leave nvim and come back. updatetime is 200ms, so CursorHold makes this feel live.
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = vim.api.nvim_create_augroup("lerd_checktime", { clear = true }),
  callback = function()
    if vim.o.buftype ~= "nofile" and vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})

-- Say so when a buffer was reloaded, rather than swapping it silently.
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = vim.api.nvim_create_augroup("lerd_changed_notice", { clear = true }),
  callback = function()
    vim.notify("Reloaded from disk: " .. vim.fn.expand("<afile>:t"), vim.log.levels.INFO)
  end,
})

-- Don't scroll past the end of the file.
-- Vim happily scrolls until the last line is at the top of the window, leaving a
-- screenful of blank space. There's no option for it, so after every scroll we
-- check whether the file's last line is sitting above the bottom of the window
-- and, if so, scroll back up (<C-Y>) until it isn't.
local eof_scrolling = false

local function clamp_to_eof()
  if eof_scrolling or vim.wo.diff or vim.bo.buftype ~= "" then
    return
  end

  local function blank_rows()
    local last = vim.fn.line("$")
    local col = math.max(1, #vim.fn.getline(last))
    local pos = vim.fn.screenpos(0, last, col)
    if pos.row == 0 then
      return 0 -- last line is below the window, nothing to clamp
    end
    local bottom = vim.fn.win_screenpos(0)[1] + vim.api.nvim_win_get_height(0) - 1
    return bottom - pos.row
  end

  eof_scrolling = true
  local ok, err = pcall(function()
    for _ = 1, 20 do
      if blank_rows() <= 0 then
        break
      end
      local before = vim.fn.winsaveview()
      vim.cmd("normal! \25") -- <C-Y>
      local after = vim.fn.winsaveview()
      if after.topline == before.topline and after.topfill == before.topfill then
        break -- already at the top, the whole file fits
      end
    end
  end)
  eof_scrolling = false
  if not ok then
    error(err)
  end
end

vim.api.nvim_create_autocmd({ "WinScrolled", "WinResized" }, {
  group = vim.api.nvim_create_augroup("lerd_no_scroll_past_eof", { clear = true }),
  callback = clamp_to_eof,
})

-- :LspRestart, which neither Neovim 0.12 nor LazyVim provides any more. Stops the
-- clients attached to this buffer and reloads it so they attach again, which is what
-- picks up files created or renamed outside the editor.
vim.api.nvim_create_user_command("LspRestart", function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })

  for _, client in ipairs(clients) do
    client:stop(true)
  end

  vim.defer_fn(function()
    vim.cmd("edit")
    vim.notify("Restarted " .. #clients .. " language server(s)", vim.log.levels.INFO)
  end, 300)
end, { desc = "Restart the language servers for this buffer" })
