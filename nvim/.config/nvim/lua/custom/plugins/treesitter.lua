return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup({})

			-- Install missing parsers (only if .so not found, to avoid recompiling on every launch)
			local parsers = {
				"c",
				"cpp",
				"go",
				"lua",
				"python",
				"rust",
				"tsx",
				"javascript",
				"typescript",
				"vimdoc",
				"vim",
				"bash",
				"php",
				"html",
				"css",
				"json",
				"yaml",
				"markdown",
				"phpdoc",
				"regex",
				"vue",
			}
			local parser_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "parser")
			local missing = {}
			for _, lang in ipairs(parsers) do
				if vim.fn.filereadable(vim.fs.joinpath(parser_dir, lang .. ".so")) == 0 then
					table.insert(missing, lang)
				end
			end
			if #missing > 0 then
				vim.cmd("TSInstall " .. table.concat(missing, " "))
			end

			-- Enable highlighting for all filetypes
			vim.api.nvim_create_autocmd("FileType", {
				callback = function()
					pcall(vim.treesitter.start)
				end,
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("nvim-treesitter-textobjects").setup({
				select = { lookahead = true },
				move = { set_jumps = true },
			})

			local select = require("nvim-treesitter-textobjects.select")
			local move = require("nvim-treesitter-textobjects.move")
			local swap = require("nvim-treesitter-textobjects.swap")

			local selects = {
				aa = "@parameter.outer",
				ia = "@parameter.inner",
				af = "@function.outer",
				["if"] = "@function.inner",
				ac = "@class.outer",
				ic = "@class.inner",
				ab = "@block.outer",
				ib = "@block.inner",
			}
			for key, query in pairs(selects) do
				vim.keymap.set({ "x", "o" }, key, function()
					select.select_textobject(query, "textobjects")
				end, { desc = "Select " .. query })
			end

			local moves = {
				{ "goto_next_start", "]m", "@function.outer" },
				{ "goto_next_start", "]]", "@class.outer" },
				{ "goto_next_end", "]M", "@function.outer" },
				{ "goto_next_end", "][", "@class.outer" },
				{ "goto_previous_start", "[m", "@function.outer" },
				{ "goto_previous_start", "[[", "@class.outer" },
				{ "goto_previous_end", "[M", "@function.outer" },
				{ "goto_previous_end", "[]", "@class.outer" },
			}
			for _, m in ipairs(moves) do
				vim.keymap.set({ "n", "x", "o" }, m[2], function()
					move[m[1]](m[3], "textobjects")
				end, { desc = "Go to " .. m[3] })
			end

			vim.keymap.set("n", "<leader>a", function()
				swap.swap_next("@parameter.inner")
			end, { desc = "Swap next parameter" })
			vim.keymap.set("n", "<leader>A", function()
				swap.swap_previous("@parameter.inner")
			end, { desc = "Swap previous parameter" })
		end,
	},
}
