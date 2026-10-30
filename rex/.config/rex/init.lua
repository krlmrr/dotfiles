rex.bind("ctrl+b", "client.mode.enter", { name = "prefix", once = true })
rex.mode("prefix", { exclusive = true })

rex.bind("prefix/ctrl+b", "pane.send_key", { key = "ctrl+b" })

rex.bind("prefix/shift+/", "client.palette.toggle")
rex.bind("prefix/s",       "client.settings")
rex.bind("prefix/shift+r", "client.config.reload")
rex.bind("prefix/b",       "client.sidebar.toggle")

rex.bind("prefix/shift+n", "session.new")
rex.bind("prefix/shift+w", "session.rename")
rex.bind("prefix/shift+d", "session.close")
rex.bind("prefix/w",       "session.switch")
rex.bind("prefix/g",       "session.switch")

rex.bind("prefix/c",       "client.tab.new")
rex.bind("prefix/shift+t", "client.tab.rename")
rex.bind("prefix/p",       "client.tab.previous")
rex.bind("prefix/n",       "client.tab.next")
rex.bind("prefix/shift+x", "client.tab.close")
for i = 1, 9 do
  rex.bind("prefix/" .. i, "client.tab.goto", { index = i })
end

rex.bind("prefix/h", "pane.focus.left")
rex.bind("prefix/j", "pane.focus.down")
rex.bind("prefix/k", "pane.focus.up")
rex.bind("prefix/l", "pane.focus.right")
rex.bind("prefix/shift+h", "pane.move.left")
rex.bind("prefix/shift+j", "pane.move.down")
rex.bind("prefix/shift+k", "pane.move.up")
rex.bind("prefix/shift+l", "pane.move.right")
rex.bind("prefix/tab",       "pane.focus_next")
rex.bind("prefix/shift+tab", "pane.focus_previous")
rex.bind("prefix/v", "pane.split.right")
rex.bind("prefix/-", "pane.split.down")
rex.bind("prefix/x", "pane.close")
rex.bind("prefix/z", "pane.zoom")

rex.bind("prefix/r", "client.mode.enter", { name = "resize" })
rex.mode("resize", { exclusive = true })
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right",
                        left = "left", down = "down", up = "up", right = "right" }) do
  rex.bind("resize/" .. key, "pane.resize", { direction = dir })
end
