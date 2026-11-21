-- Theme switcher: detects macOS appearance and applies appropriate colorscheme
local Theme = {}

-- Theme-aware colors (single source of truth — change here, propagates everywhere)
Theme.colors = {
	dark = {
		-- semantic palette
		accent = "#61afef",
		bg_highlight = "#313640", -- One Half Dark cursor line
		fg = "#dcdfe4", -- One Half Dark foreground, matches ghostty
		fg_muted = "#5c6370",
		bg_float = "#282c34",
		inlay_hint = "#848B98",
		-- onedark palette overrides (resolved by $name in highlights).
		-- red, bg1 and bg3 retint onedark to One Half Dark, ghostty's theme.
		red = "#e06c75",
		bg1 = "#313640",
		bg3 = "#474e5d",
		comment = "#61AEEF",
		cyan = "#7aa2f7",
		orange = "#e5c07b",
	},
	light = {
		accent = "#1e66f5",
		bg_highlight = "#dce0e8", -- Catppuccin Latte "crust" - matches neo-tree cursor line
		fg = "#4c4f69",
		fg_muted = "#8c8fa1",
		bg_float = "#eff1f5",
		inlay_hint = "#8c8fa1",
	},
}

local omarchy = require("config.omarchy-theme")

local OWN_OMARCHY_THEME = "onedark-flat"

function Theme.get_colors()
	return Theme.active or Theme.colors[vim.o.background] or Theme.colors.dark
end

-- Detect system appearance (returns "dark" or "light")
function Theme.get_system_appearance()
	if vim.fn.has("mac") == 1 then
		local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
		if handle then
			local result = handle:read("*a")
			handle:close()
			if result:match("Dark") then
				return "dark"
			end
		end
		return "light"
	end

	-- Linux: query the freedesktop portal first — works on COSMIC, GNOME, KDE.
	-- Returns uint32: 0 = no preference, 1 = prefer dark, 2 = prefer light.
	local handle = io.popen(
		"gdbus call --session --dest org.freedesktop.portal.Desktop --object-path /org/freedesktop/portal/desktop --method org.freedesktop.portal.Settings.Read org.freedesktop.appearance color-scheme 2>/dev/null"
	)
	if handle then
		local result = handle:read("*a")
		handle:close()
		local n = result:match("uint32 (%d)")
		if n == "1" then
			return "dark"
		end
		if n == "2" then
			return "light"
		end
		-- n == "0" or no match: fall through to gsettings
	end

	-- Fallback: gsettings (GNOME-native; on COSMIC this returns 'default'
	-- because COSMIC doesn't write GNOME's GSettings schema, so 'default'
	-- here means "unset" not "light" — treat it as dark).
	handle = io.popen("gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null")
	if handle then
		local result = handle:read("*a")
		handle:close()
		if result:match("prefer%-light") then
			return "light"
		end
	end

	return "dark"
end

-- Apply highlights that depend on the active palette (called after each colorscheme loads).
-- Both dark and light themes share these — only the resolved colors differ.
local function apply_plugin_highlights()
	local colors = Theme.get_colors()

	-- Editor chrome
	vim.api.nvim_set_hl(0, "CursorLine", { bg = colors.bg_highlight })
	vim.api.nvim_set_hl(0, "CursorLineNr", { fg = colors.fg, bg = "NONE" })
	vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
	vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })
	vim.api.nvim_set_hl(0, "WinBar", { fg = colors.fg_muted, bg = "NONE" })
	vim.api.nvim_set_hl(0, "WinBarNC", { fg = colors.fg_muted, bg = "NONE" })
	vim.api.nvim_set_hl(0, "LspInlayHint", { fg = colors.inlay_hint, bg = "NONE" })

	-- Floating windows
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
	vim.api.nvim_set_hl(0, "FloatBorder", { fg = colors.fg_muted, bg = "NONE" })
	vim.api.nvim_set_hl(0, "FloatTitle", { fg = colors.fg, bg = "NONE" })

	-- Dashboard
	vim.api.nvim_set_hl(0, "DashboardShortCut", { fg = colors.accent, bg = "NONE" })
	vim.api.nvim_set_hl(0, "DashboardShortCutCursor", { fg = colors.accent, bg = colors.bg_highlight })
	vim.api.nvim_set_hl(0, "DashboardHeader", { fg = colors.accent, bg = "NONE" })
	vim.api.nvim_set_hl(0, "DashboardMruTitle", { fg = colors.fg, bg = "NONE" })
	vim.api.nvim_set_hl(0, "DashboardMruIcon", { fg = colors.fg, bg = "NONE" })
	vim.api.nvim_set_hl(0, "DashboardFiles", { fg = colors.fg, bg = "NONE" })
	vim.api.nvim_set_hl(0, "DashboardFooter", { fg = colors.fg, bg = "NONE" })

	vim.api.nvim_set_hl(0, "NoiceMiniBorder", { fg = colors.accent, bg = colors.bg_float })
	vim.api.nvim_set_hl(0, "NoiceMiniText", { fg = colors.fg, bg = colors.bg_float })
	vim.api.nvim_set_hl(0, "NoiceConfirmBorder", { fg = colors.accent, bg = colors.bg_float })
	vim.api.nvim_set_hl(0, "NoiceCmdlinePopupBorder", { fg = colors.accent })
	vim.api.nvim_set_hl(0, "NoiceCmdlinePopupTitle", { fg = colors.accent })
	vim.api.nvim_set_hl(0, "NoiceCmdlineIcon", { fg = colors.accent })
	vim.api.nvim_set_hl(0, "NoiceCmdlinePrompt", { fg = colors.accent })
	vim.api.nvim_set_hl(0, "NoiceFormatTitle", { fg = colors.accent })
	vim.api.nvim_set_hl(0, "NoiceConfirmText", { fg = colors.fg, bg = "NONE" })
	vim.api.nvim_set_hl(0, "NoiceFormatConfirm", { fg = colors.fg, bg = "NONE" })
	vim.api.nvim_set_hl(0, "NoiceFormatConfirmDefault", { fg = colors.fg, bg = "NONE", bold = true })

	-- Dressing
	vim.api.nvim_set_hl(0, "DressingInputBorder", { fg = colors.accent, bg = colors.bg_float })
	vim.api.nvim_set_hl(0, "DressingInputTitle", { fg = colors.bg_float, bg = colors.accent, bold = true })
	vim.api.nvim_set_hl(0, "DressingInputText", { fg = colors.fg, bg = colors.bg_float })
	vim.api.nvim_set_hl(0, "DressingInputNormalFloat", { bg = colors.bg_float })
	vim.api.nvim_set_hl(0, "DressingSelectCursorLine", { bg = colors.bg_highlight })

	-- Neo-tree
	vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "NONE" })
	vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "NONE" })
	vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { bg = "NONE" })
	vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { fg = colors.fg, bold = false })
	vim.api.nvim_set_hl(0, "NeoTreeFileName", { fg = colors.fg, bold = false })
	vim.api.nvim_set_hl(0, "NeoTreeRootName", { fg = colors.fg, bold = false })
	vim.api.nvim_set_hl(0, "NeoTreeCursorLine", { bg = colors.bg_highlight })

	-- Indent blankline / Rainbow
	vim.api.nvim_set_hl(0, "IblIndent", { fg = colors.bg_highlight })
end

-- Apply dark theme (onedark, retinted to One Half Dark)
local function apply_dark_theme()
	Theme.active = nil
	vim.o.background = "dark"
	local colors = Theme.colors.dark
	require("onedark").setup({
		style = "dark",
		colors = {
			fg = colors.fg,
			red = colors.red,
			bg1 = colors.bg1,
			bg3 = colors.bg3,
			comment = colors.comment,
			cyan = colors.cyan,
			orange = colors.orange,
		},
		highlights = {
			["@keyword"] = { fg = "$purple" },
			["@function.builtin"] = { fg = "$blue" },
			["@type.builtin"] = { fg = "$yellow" },
			["String"] = { fg = "$green" },
			["@string"] = { fg = "$green" },
			["Comment"] = { fg = "$comment" },
			["@comment"] = { fg = "$comment" },
			["@comment.lua"] = { fg = "$comment" },
			["@lsp.type.comment"] = { fg = "$comment" },
			["@lsp.type.comment.lua"] = { fg = "$comment" },
			["@lsp.type.function"] = { fg = "$blue", fmt = "none" },
			["@lsp.type.method"] = { fmt = "none" },
			["@lsp.type.class"] = { fmt = "none" },
			["@lsp.type.namespace"] = { fmt = "none" },
			["@lsp.typemod.function.declaration"] = { fmt = "none" },
			["@lsp.typemod.method.declaration"] = { fmt = "none" },
			["@tag"] = { fg = "$red" },
			["@tag.delimiter"] = { fg = "$fg" },
			["@tag.attribute"] = { fg = "$yellow" },
			["@tag.builtin"] = { fg = "$red" },
			["@tag.vue"] = { fg = "$red" },
			["@tag.delimiter.vue"] = { fg = "$fg" },
			["@tag.attribute.vue"] = { fg = "$yellow" },
			["@tag.blade"] = { fg = "$red" },
			["@tag.delimiter.blade"] = { fg = "$fg" },
			["@tag.attribute.blade"] = { fg = "$yellow" },
			["@punctuation.bracket.blade"] = { fg = "$yellow" },
			["@variable.php"] = { fg = "$red" },
			["@variable.php_only"] = { fg = "$red" },
			["@punctuation.bracket.php"] = { fg = "$yellow" },
			["@punctuation.bracket.php_only"] = { fg = "$yellow" },
			["@variable"] = { fg = "$red" },
			["@lsp.type.variable"] = { fg = "$red" },
			["@lsp.type.variable.javascript"] = { fg = "$red" },
			["@lsp.type.variable.typescript"] = { fg = "$red" },
			["@lsp.type.variable.typescriptreact"] = { fg = "$red" },
			["@lsp.type.variable.javascriptreact"] = { fg = "$red" },
			["@variable.builtin"] = { fg = "$yellow" },
			["@lsp.typemod.variable.defaultLibrary"] = { fg = "$yellow" },
			["@function.call"] = { fg = "$blue" },
			["@lsp.type.function.php"] = { fg = "$blue", fmt = "none" },
			["@operator"] = { fg = "$cyan" },
			["@keyword.conditional.ternary"] = { fg = "$cyan" },
			["@lsp.type.operator"] = { fg = "$cyan" },
			["@lsp.type.operator.typescript"] = { fg = "$cyan" },
			["@lsp.type.operator.typescriptreact"] = { fg = "$cyan" },
			["@punctuation.delimiter"] = { fg = "$cyan" },
			["@punctuation.delimiter.typescript"] = { fg = "$cyan" },
			["@punctuation.delimiter.typescriptreact"] = { fg = "$cyan" },
			["@text.html"] = { fg = "$fg" },
			["@constant.blade"] = { fg = "$cyan" },
			["@variable.blade"] = { fg = "$cyan" },
		},
	})
	require("onedark").load()

	apply_plugin_highlights()
end

-- Apply light theme (catppuccin latte)
local function apply_light_theme()
	Theme.active = nil
	vim.o.background = "light"
	require("catppuccin").setup({
		flavour = "latte",
		transparent_background = false,
		integrations = {
			cmp = true,
			gitsigns = true,
			nvimtree = true,
			neotree = true,
			treesitter = true,
			indent_blankline = { enabled = true },
			native_lsp = { enabled = true },
			dashboard = true,
		},
	})
	vim.cmd.colorscheme("catppuccin-latte")

	apply_plugin_highlights()
end

local function apply_omarchy_theme(plugins, colorscheme, palette)
	vim.o.background = palette.mode == "light" and "light" or "dark"
	omarchy.load(plugins)
	vim.cmd.colorscheme(colorscheme)
	Theme.active = {
		accent = palette.accent,
		bg_highlight = palette.lighter_background or palette.selection,
		fg = palette.foreground,
		fg_muted = palette.muted or palette.dark_foreground,
		bg_float = palette.background,
		inlay_hint = palette.muted or palette.dark_foreground,
	}
	apply_plugin_highlights()
end

local function try_omarchy_theme(name)
	if not name or name == OWN_OMARCHY_THEME then
		return false
	end
	local plugins, colorscheme = omarchy.current()
	local palette = omarchy.palette()
	if not colorscheme or not palette then
		return false
	end
	local ok, err = pcall(apply_omarchy_theme, plugins, colorscheme, palette)
	if not ok then
		vim.notify("Omarchy theme " .. name .. " failed: " .. tostring(err), vim.log.levels.WARN)
	end
	return ok
end

-- Apply theme based on current system appearance
function Theme.apply()
	local name = omarchy.name()
	Theme.omarchy_name = name
	if try_omarchy_theme(name) then
		return
	end
	local appearance = Theme.get_system_appearance()
	if appearance == "light" then
		apply_light_theme()
	else
		apply_dark_theme()
	end
end

-- Toggle between light and dark (manual override)
function Theme.toggle()
	if vim.o.background == "dark" then
		apply_light_theme()
	else
		apply_dark_theme()
	end
end

-- Sync with system appearance (call on FocusGained)
function Theme.sync()
	if omarchy.name() ~= Theme.omarchy_name then
		return Theme.apply()
	end
	if Theme.active then
		return
	end
	local appearance = Theme.get_system_appearance()
	local current = vim.o.background
	if appearance ~= current then
		Theme.apply()
	end
end

return Theme
