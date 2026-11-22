return {
	"nvim-mini/mini.icons",
	lazy = true,
	opts = {
		file = {
			[".env"] = { glyph = "󰌆", hl = "MiniIconsYellow" },
			[".env.example"] = { glyph = "󰌆", hl = "MiniIconsYellow" },
			[".env.local"] = { glyph = "󰌆", hl = "MiniIconsYellow" },
			[".env.testing"] = { glyph = "󰌆", hl = "MiniIconsYellow" },
			[".env.production"] = { glyph = "󰌆", hl = "MiniIconsYellow" },
			artisan = { glyph = "", hl = "MiniIconsRed" },
		},
		extension = {
			sh = { glyph = "", hl = "MiniIconsGreen" },
			hook = { glyph = "", hl = "MiniIconsGreen" },
			log = { glyph = "󰈙", hl = "MiniIconsGrey" },
			lock = { glyph = "󰌾", hl = "MiniIconsGrey" },
			service = { glyph = "", hl = "MiniIconsGrey" },
			timer = { glyph = "", hl = "MiniIconsGrey" },
			plist = { glyph = "", hl = "MiniIconsGrey" },
			heic = { glyph = "󰸭", hl = "MiniIconsAzure" },
		},
		filetype = {
			sh = { glyph = "", hl = "MiniIconsGreen" },
			ini = { glyph = "󰒓", hl = "MiniIconsGrey" },
			properties = { glyph = "󰒓", hl = "MiniIconsGrey" },
		},
	},
	init = function()
		package.preload["nvim-web-devicons"] = function()
			require("mini.icons").mock_nvim_web_devicons()
			return package.loaded["nvim-web-devicons"]
		end
	end,
}
