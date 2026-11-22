-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- Omarchy strips "default-opacity" from browsers and gives them their own "1.0 0.985" rule.
o.window({ tag = "default-opacity" }, { opacity = "1 1" })
o.window({ tag = "firefox-based-browser" }, { opacity = "1 1" })
o.window({ tag = "chromium-based-browser" }, { opacity = "1 1" })

o.window({ class = "^steam$" }, { tile = true })
o.window({ class = "^steam_app_\\d+$" }, { center = true })

-- These are apps used for communication and should float.
o.window({ class = "^slack$" }, { float = true })
o.window({ class = "^discord$" }, { float = true })

-- Omarchy's Super+C/V send Ctrl+Shift+C/V only to windows tagged as terminals.
o.window({ class = "^herdr-app$" }, { tag = "+terminal" })

-- Hacknet (native FNA build) breaks its own input mapping when it drops out of
-- fullscreen and gets tiled into a column, so keep it fullscreen and floating.
o.window({ class = "^Hacknet\\.bin\\.x86_64$" }, { float = true, fullscreen = true, idle_inhibit = "fullscreen" })

hl.config({
  general = {
    resize_on_border = true,
  },

  decoration = {
    rounding = 8,
  },
})

-- Opt another application in to Omarchy's standard transparency.
-- Find its class with: hyprctl clients
-- o.transparent_window("my-app")
-- o.transparent_window("my-app", "0.9 0.85") -- Custom active/inactive opacity.
