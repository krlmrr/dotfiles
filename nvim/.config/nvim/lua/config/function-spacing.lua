local M = {}

local FUNCTION_NODES = {
	function_item = true,
	function_definition = true,
	function_declaration = true,
	generator_function_declaration = true,
	method_definition = true,
	method_declaration = true,
	constructor_declaration = true,
}

local DOC_COMMENT_ATTRIBUTE_OR_DECORATOR_PREFIXES = { "//", "#", "/*", "*", "@", "--" }

local function trimmed(line)
	return line:match("^%s*(.-)%s*$")
end

local function is_blank(line)
	return line:match("^%s*$") ~= nil
end

local function belongs_to_function_below(line)
	local text = trimmed(line)
	for _, prefix in ipairs(DOC_COMMENT_ATTRIBUTE_OR_DECORATOR_PREFIXES) do
		if text:sub(1, #prefix) == prefix then
			return true
		end
	end
	return false
end

local function opens_block(line)
	local text = trimmed(line)
	return text:match("[{(%[:]$") ~= nil or text:sub(1, 1) == "<"
end

local function closes_block(line)
	local text = trimmed(line)
	return text:match("^[})%]]") ~= nil or text:match("^end%f[%W]") ~= nil or text:sub(1, 2) == "</"
end

local function with_wrappers_like_export(node)
	local parent = node:parent()
	while parent and parent:parent() do
		local start_row, _, end_row, end_col = node:range()
		local parent_start_row, _, parent_end_row, parent_end_col = parent:range()
		if parent_start_row ~= start_row or parent_end_row ~= end_row or parent_end_col ~= end_col then
			break
		end
		node, parent = parent, parent:parent()
	end
	return node
end

local function sits_on_its_own_lines(lines, node)
	local start_row, start_col, end_row, end_col = node:range()
	local before = lines[start_row + 1]:sub(1, start_col)
	local after = (lines[end_row + 1] or ""):sub(end_col + 1)
	return is_blank(before) and (is_blank(after) or after:match("^%s*[;,]%s*$") ~= nil)
end

local function first_row_including_attached_lines(lines, start_row)
	local row = start_row
	while row > 0 and belongs_to_function_below(lines[row]) do
		row = row - 1
	end
	return row
end

local function rows_to_insert_blank_above(buf, lines)
	local ok, parser = pcall(vim.treesitter.get_parser, buf)
	if not ok or not parser then
		return {}
	end
	parser:parse(true)

	local rows = {}
	parser:for_each_tree(function(tree)
		local function visit(node)
			local whole = FUNCTION_NODES[node:type()] and with_wrappers_like_export(node)
			if whole and sits_on_its_own_lines(lines, whole) then
				local start_row, _, end_row = whole:range()
				local top = first_row_including_attached_lines(lines, start_row)
				local line_above, line_below = lines[top], lines[end_row + 2]
				if line_above and not is_blank(line_above) and not opens_block(line_above) then
					rows[top] = true
				end
				if line_below and not is_blank(line_below) and not closes_block(line_below) then
					rows[end_row + 1] = true
				end
			end
			for child in node:iter_children() do
				visit(child)
			end
		end
		visit(tree:root())
	end)

	local bottom_up = vim.tbl_keys(rows)
	table.sort(bottom_up, function(a, b)
		return a > b
	end)
	return bottom_up
end

function M.apply(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local rows = rows_to_insert_blank_above(buf, lines)
	if #rows == 0 then
		return
	end

	local win = vim.fn.bufwinid(buf)
	local cursor = win ~= -1 and vim.api.nvim_win_get_cursor(win)

	pcall(vim.cmd.undojoin)
	for _, row in ipairs(rows) do
		vim.api.nvim_buf_set_lines(buf, row, row, false, { "" })
		if cursor and row < cursor[1] then
			cursor[1] = cursor[1] + 1
		end
	end
	if cursor then
		vim.api.nvim_win_set_cursor(win, cursor)
	end
end

return M
