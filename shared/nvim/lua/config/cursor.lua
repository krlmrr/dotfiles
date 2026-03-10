-- Cursor visibility utilities (used by dashboard, dressing, neo-tree)
local M = {}

function M.hide()
  vim.cmd("highlight Cursor blend=100")
  vim.opt.guicursor:append("a:Cursor/lCursor")
end

function M.show()
  vim.cmd("highlight Cursor blend=0")
  vim.opt.guicursor:remove("a:Cursor/lCursor")
end

return M
