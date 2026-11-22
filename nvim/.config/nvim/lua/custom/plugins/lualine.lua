return {
	"nvim-lualine/lualine.nvim",
	config = function()
		local custom_theme = {
			normal = {
				a = { fg = "#abb2bf", bg = "NONE" },
				b = { fg = "#abb2bf", bg = "NONE" },
				c = { fg = "#5c6370", bg = "NONE" },
				x = { fg = "#abb2bf", bg = "NONE" },
				y = { fg = "#abb2bf", bg = "NONE" },
				z = { fg = "#282c34", bg = "#98c379", gui = "bold" },
			},
			insert = {
				z = { fg = "#282c34", bg = "#61afef", gui = "bold" },
			},
			visual = {
				z = { fg = "#282c34", bg = "#c678dd", gui = "bold" },
			},
			replace = {
				z = { fg = "#282c34", bg = "#e06c75", gui = "bold" },
			},
			command = {
				z = { fg = "#282c34", bg = "#e5c07b", gui = "bold" },
			},
			inactive = {
				a = { fg = "#5c6370", bg = "#3e4452" },
				b = { fg = "#5c6370", bg = "NONE" },
				c = { fg = "#5c6370", bg = "NONE" },
				z = { fg = "#5c6370", bg = "#3e4452" },
			},
		}

		local filetype_names = {
			["neo-tree"] = "",
			["neo-tree-popup"] = "",
			snacks_picker_input = "",
			DressingInput = "",
			DressingSelect = "",
			sh = "Shell",
			php = "PHP",
			javascript = "JavaScript",
			typescript = "TypeScript",
			javascriptreact = "JSX",
			typescriptreact = "TSX",
			json = "JSON",
			jsonc = "JSONC",
			html = "HTML",
			css = "CSS",
			scss = "SCSS",
			yaml = "YAML",
			toml = "TOML",
			xml = "XML",
			sql = "SQL",
			csv = "CSV",
			svg = "SVG",
			qml = "QML",
			graphql = "GraphQL",
			gitcommit = "Git Commit",
			gitignore = "Git Ignore",
			gitconfig = "Git Config",
			dosini = "INI",
			hyprlang = "Hyprland",
		}

		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = custom_theme,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				globalstatus = true,
				disabled_filetypes = {
					statusline = { "dashboard" },
				},
			},
			sections = {
				lualine_a = {
					{
						"branch",
						cond = function()
							return vim.bo.buftype ~= "terminal"
						end,
					},
					{
						"diff",
						cond = function()
							return vim.bo.buftype ~= "terminal"
						end,
					},
				},
				lualine_b = {},
				lualine_c = {},
				lualine_x = {},
				lualine_y = {
					{
						"filetype",
						cond = function()
							return vim.bo.buftype ~= "terminal"
						end,
						fmt = function(str)
							return filetype_names[str] or str:sub(1, 1):upper() .. str:sub(2)
						end,
					},
				},
				lualine_z = { { "mode", separator = { left = "\u{e0b2}" } } },
			},
		})
	end,
}
