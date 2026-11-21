-- Disable built-in plugins
vim.g.loaded_matchparen = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Line numbers
vim.wo.number = true
vim.wo.relativenumber = true
vim.o.numberwidth = 1

function _G.StatusColumn()
	local lnum = vim.v.lnum
	local relnum = vim.v.relnum
	if relnum == 0 then
		return "%#CursorLineNr#" .. lnum .. "%*   "
	else
		return relnum .. "   "
	end
end
vim.opt.statuscolumn = "%=%{%v:lua.StatusColumn()%}"

-- Tabs and indentation
vim.o.tabstop = 4
vim.o.expandtab = true
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.autoindent = true
vim.o.breakindent = true

-- Search
vim.o.hlsearch = true
vim.o.ignorecase = true
vim.o.smartcase = true

-- UI
vim.o.wrap = false
vim.o.cursorline = false
vim.o.scrolloff = 10
vim.o.sidescrolloff = 0
vim.o.termguicolors = true
vim.wo.signcolumn = "no"
vim.wo.foldcolumn = "0"
vim.o.laststatus = 3 -- Global statusline (works with lualine globalstatus)
vim.o.cmdheight = 1

-- Files
vim.o.swapfile = false
vim.o.undofile = true
vim.o.autoread = true
vim.opt.fillchars:append({ eob = " " })

-- Auto-reload files when changed externally (real-time with libuv)
local watch_handles = {}

local function unwatch_buffer(bufnr)
	local handle = watch_handles[bufnr]
	if handle then
		handle:stop()
		handle:close()
		watch_handles[bufnr] = nil
	end
end

local function watch_buffer(bufnr)
	unwatch_buffer(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
		return
	end
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	if filepath == "" or not vim.uv.fs_stat(filepath) then
		return
	end

	local handle = vim.uv.new_fs_event()
	watch_handles[bufnr] = handle
	handle:start(filepath, {}, function(err)
		if err then
			return
		end
		vim.defer_fn(function()
			if not vim.api.nvim_buf_is_valid(bufnr) then
				return
			end
			if not vim.bo[bufnr].modified then
				vim.cmd("checktime " .. bufnr)
				vim.cmd("redraw")
			end
			watch_buffer(bufnr)
		end, 100)
	end)
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
	callback = function(args)
		watch_buffer(args.buf)
	end,
})

vim.api.nvim_create_autocmd("BufDelete", {
	callback = function(args)
		unwatch_buffer(args.buf)
	end,
})

-- Mouse and clipboard
vim.o.confirm = true
vim.o.mouse = "a"
vim.o.clipboard = "unnamedplus"
if vim.fn.has("linux") == 1 then
	require("config.remote_clipboard").setup()
end

-- Prevent scrolling past end of file with mouse
-- The wheel scrolls the window under the mouse, not the focused one, so measure that window
vim.keymap.set({ "n", "v", "i" }, "<ScrollWheelDown>", function()
	local win = vim.fn.getmousepos().winid
	if win == 0 then
		win = vim.api.nvim_get_current_win()
	end
	local max_top = vim.api.nvim_win_call(win, function()
		return math.max(1, vim.fn.line("$") - vim.api.nvim_win_get_height(0) + 1)
	end)
	if vim.fn.line("w0", win) >= max_top then
		return ""
	end
	-- A wheel tick moves several lines, so pull back if it overshot the last line
	vim.schedule(function()
		if vim.api.nvim_win_is_valid(win) and vim.fn.line("w0", win) > max_top then
			vim.api.nvim_win_call(win, function()
				vim.fn.winrestview({ topline = max_top })
			end)
		end
	end)
	return "<ScrollWheelDown>"
end, { expr = true, silent = true })

local function window_under_mouse()
	local win = vim.fn.getmousepos().winid
	if win == 0 then
		return vim.api.nvim_get_current_win()
	end
	return win
end

local function max_leftcol(win)
	return vim.api.nvim_win_call(win, function()
		local text_width = vim.api.nvim_win_get_width(0) - vim.fn.getwininfo(win)[1].textoff
		local longest = 0
		for _, line in ipairs(vim.api.nvim_buf_get_lines(0, vim.fn.line("w0") - 1, vim.fn.line("w$"), false)) do
			longest = math.max(longest, vim.fn.strdisplaywidth(line))
		end
		return math.max(0, longest - text_width + 1)
	end)
end

local function leftcol(win)
	return vim.api.nvim_win_call(win, function()
		return vim.fn.winsaveview().leftcol
	end)
end

vim.keymap.set({ "n", "v", "i" }, "<ScrollWheelLeft>", function()
	if leftcol(window_under_mouse()) == 0 then
		return ""
	end
	return "<ScrollWheelLeft>"
end, { expr = true, silent = true })

vim.keymap.set({ "n", "v", "i" }, "<ScrollWheelRight>", function()
	local win = window_under_mouse()
	local limit = max_leftcol(win)
	if leftcol(win) >= limit then
		return ""
	end
	vim.schedule(function()
		if vim.api.nvim_win_is_valid(win) and leftcol(win) > limit then
			vim.api.nvim_win_call(win, function()
				vim.fn.winrestview({ leftcol = limit })
			end)
		end
	end)
	return "<ScrollWheelRight>"
end, { expr = true, silent = true })

-- Keep cursor centered after window resize
vim.api.nvim_create_autocmd("WinResized", {
	callback = function()
		for _, win in ipairs(vim.v.event.windows) do
			if vim.api.nvim_win_is_valid(win) then
				local buf = vim.api.nvim_win_get_buf(win)
				local ft = vim.bo[buf].filetype
				-- Skip special buffers
				if ft ~= "neo-tree" and ft ~= "dashboard" and ft ~= "" then
					vim.api.nvim_win_call(win, function()
						vim.cmd("normal! zz")
					end)
				end
			end
		end
	end,
})

-- Equalize splits on terminal resize (excluding neo-tree)
vim.api.nvim_create_autocmd("VimResized", {
	callback = function()
		-- Get neo-tree width if it exists
		local neotree_width = 0
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local buf = vim.api.nvim_win_get_buf(win)
			if vim.bo[buf].filetype == "neo-tree" then
				neotree_width = vim.api.nvim_win_get_width(win)
				break
			end
		end
		-- Equalize all windows then restore neo-tree width
		vim.cmd("wincmd =")
		if neotree_width > 0 then
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				local buf = vim.api.nvim_win_get_buf(win)
				if vim.bo[buf].filetype == "neo-tree" then
					vim.api.nvim_win_set_width(win, neotree_width)
					break
				end
			end
		end
	end,
})

-- Performance (updatetime also controls CursorHold delay)
vim.o.updatetime = 250

-- Auto-reload on cursor idle (skip special windows)
vim.api.nvim_create_autocmd("CursorHold", {
	callback = function()
		if vim.fn.getcmdwintype() ~= "" then
			return
		end
		vim.cmd("checktime")
	end,
})
vim.o.timeoutlen = 300

-- Completion
vim.o.completeopt = "menuone,noselect"

-- Misc
vim.opt.shortmess:append("s")

-- Diagnostics
vim.diagnostic.config({
	underline = false,
})

-- Inlay hints
vim.lsp.inlay_hint.enable(false)

-- Remove underline styling
vim.api.nvim_set_hl(0, "@lsp.type.function", {})
vim.api.nvim_set_hl(0, "@lsp.type.method", {})
vim.api.nvim_set_hl(0, "LspReferenceText", {})
vim.api.nvim_set_hl(0, "LspReferenceRead", {})
vim.api.nvim_set_hl(0, "LspReferenceWrite", {})
