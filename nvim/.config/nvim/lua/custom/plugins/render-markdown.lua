return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown" },
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
	opts = {
		render_modes = { "n", "c", "t" },
		anti_conceal = { enabled = false },
		heading = { backgrounds = {}, position = "inline" },
	},
}
