return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},
	config = function(_, opts)
		require("noice").setup(opts)
		local cmdline = require("noice.ui.cmdline")
		local on_confirm = cmdline.on_confirm
		local on_show = cmdline.on_show
		local on_hide = cmdline.on_hide
		local held_hide
		local hide_token = 0

		cmdline.on_confirm = function(message)
			for _, line in ipairs(message._lines) do
				for _, text in ipairs(line._texts) do
					if text.extmark then
						text.extmark.hl_group = "NoiceConfirmText"
					end
				end
			end
			message:newline()
			require("config.cursor").hide()
			return on_confirm(message)
		end

		cmdline.on_hide = function(...)
			if cmdline._on_hide then
				held_hide = cmdline._on_hide
				cmdline._on_hide = nil
				hide_token = hide_token + 1
				local token = hide_token
				vim.defer_fn(function()
					if token == hide_token and held_hide then
						local release = held_hide
						held_hide = nil
						release()
						require("noice.ui.state").clear("msg_show")
						if vim.bo.filetype ~= "neo-tree" then
							require("config.cursor").show()
						end
					end
				end, 100)
			end
			return on_hide(...)
		end

		cmdline.on_show = function(event, content, pos, firstc, prompt, ...)
			if firstc == "" and (held_hide or cmdline._on_hide) then
				if held_hide then
					cmdline._on_hide = held_hide
					held_hide = nil
					hide_token = hide_token + 1
				end
				return
			end
			return on_show(event, content, pos, firstc, prompt, ...)
		end
	end,
	opts = {
		views = {
			cmdline_popup = {
				position = { row = "50%", col = "50%" },
			},
			cmdline_popupmenu = {
				position = { row = "58%", col = "50%" },
			},
			confirm = {
				position = { row = "50%", col = "50%" },
			},
			mini = {
				timeout = 3000,
				position = { row = -3 },
				border = { style = "rounded", padding = { 0, 1 } },
				win_options = {
					winblend = 0,
					winhighlight = { Normal = "NoiceMiniText", FloatBorder = "NoiceMiniBorder" },
				},
			},
		},
		lsp = {
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
				["cmp.entry.get_documentation"] = true,
			},
			-- blink.cmp shows signature help; noice's adds a blank line under it
			signature = { enabled = false },
		},
		presets = {
			bottom_search = true,
			command_palette = true,
			long_message_to_split = false,
			inc_rename = false,
			lsp_doc_border = true,
		},
		routes = {
			-- Skip noisy messages entirely (must be before general routing)
			{ filter = { event = "msg_show", kind = "progress" }, opts = { skip = true } },
			{ filter = { event = "msg_show", find = "lines in buffer" }, opts = { skip = true } },
			{ filter = { event = "notify", find = "lines in buffer" }, opts = { skip = true } },
			{ filter = { event = "msg_show", find = "E162" }, opts = { skip = true } },
			{ filter = { event = "notify", find = "Initializing" }, opts = { skip = true } },
			{ filter = { event = "msg_show", find = "Initializing" }, opts = { skip = true } },
			{ filter = { event = "lsp", kind = "progress" }, opts = { skip = true } },
			{ filter = { event = "notify", find = "No information available" }, opts = { skip = true } },
			{ filter = { event = "msg_show", find = "No information available" }, opts = { skip = true } },
			{ filter = { event = "notify", find = "window%-picker" }, opts = { skip = true } },
			{ filter = { event = "notify", find = "[Ll]oading" }, opts = { skip = true } },
			{ filter = { event = "msg_show", find = "[Ll]oading" }, opts = { skip = true } },
			{ filter = { event = "msg_show", find = "modifiable" }, opts = { skip = true } },
			{ filter = { event = "notify", find = "modifiable" }, opts = { skip = true } },
			{ filter = { event = "msg_show", find = "Operation canceled" }, opts = { skip = true } },
			{ filter = { event = "notify", find = "Operation canceled" }, opts = { skip = true } },
			{ filter = { event = "notify", find = "Deleted" }, opts = { skip = true } },
			{ filter = { event = "msg_show", find = "Deleted" }, opts = { skip = true } },
			{ filter = { event = "msg_show", kind = { "confirm", "confirm_sub" } }, view = "confirm" },
			-- Route remaining messages to mini view
			{ filter = { event = "msg_show" }, view = "mini" },
			{ filter = { event = "notify" }, view = "mini" },
		},
	},
}
