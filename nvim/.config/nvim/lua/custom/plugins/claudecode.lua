return {
	"coder/claudecode.nvim",
	event = "VeryLazy", -- Start the IDE server so `claude` in another pane can /ide connect
	dependencies = {
		"folke/snacks.nvim",
	},
	opts = {},
}
