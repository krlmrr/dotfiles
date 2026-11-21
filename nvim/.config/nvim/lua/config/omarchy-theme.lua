local M = {}

local STATE = vim.fn.expand("~/.local/state/omarchy/current")
local THEME_DIRS = { "/usr/share/omarchy/themes", vim.fn.expand("~/.config/omarchy/themes") }

M.OWN_PLUGINS = { ["navarasu/onedark.nvim"] = true, ["catppuccin/nvim"] = true }

local function read(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local text = file:read("*a")
	file:close()
	return text
end

function M.name()
	local text = read(STATE .. "/theme.name")
	return text and vim.trim(text) or nil
end

function M.palette()
	local text = read(STATE .. "/theme/colors.toml")
	if not text then
		return nil
	end
	local palette = {}
	for key, value in text:gmatch('([%w_]+)%s*=%s*"([^"]*)"') do
		palette[key] = value
	end
	return palette
end

function M.parse(path)
	local ok, specs = pcall(dofile, path)
	local plugins, colorscheme = {}, nil
	if not ok or type(specs) ~= "table" then
		return plugins, colorscheme
	end
	for _, spec in ipairs(specs) do
		if type(spec) == "table" and type(spec[1]) == "string" then
			if spec[1] == "LazyVim/LazyVim" then
				colorscheme = spec.opts and spec.opts.colorscheme
			else
				table.insert(plugins, spec)
			end
		end
	end
	return plugins, colorscheme
end

function M.current()
	return M.parse(STATE .. "/theme/neovim.lua")
end

function M.lazy_specs()
	local specs, seen = {}, {}
	for _, dir in ipairs(THEME_DIRS) do
		for _, path in ipairs(vim.fn.glob(dir .. "/*/neovim.lua", false, true)) do
			for _, spec in ipairs((M.parse(path))) do
				local repo = spec[1]
				if not seen[repo] and not M.OWN_PLUGINS[repo] then
					seen[repo] = true
					table.insert(specs, { repo, name = spec.name, dependencies = spec.dependencies, lazy = true })
				end
			end
		end
	end
	return specs
end

local MERGED_SETUP_STATE = { onedark = "onedark_config" }

local function find_plugin(repo)
	for _, plugin in pairs(require("lazy.core.config").plugins) do
		if plugin[1] == repo then
			return plugin
		end
	end
end

function M.load(plugins)
	for _, spec in ipairs(plugins) do
		local plugin = find_plugin(spec[1])
		if plugin then
			require("lazy").load({ plugins = { plugin.name } })
			if spec.opts then
				local main = require("lazy.core.loader").get_main(plugin)
				if main then
					if MERGED_SETUP_STATE[main] then
						vim.g[MERGED_SETUP_STATE[main]] = nil
					end
					require(main).setup(spec.opts)
				end
			end
		end
	end
end

return M
