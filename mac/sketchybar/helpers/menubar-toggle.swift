import AppKit
import Foundation

// Trigger anywhere the sketchybar bar is drawn, not just the top few pixels —
// otherwise hovering the bar below ~10px (e.g. the right-side items) never
// reveals the native menu bar. Matches sketchybarrc's bar: height 24 + y_offset 3.
let triggerZone: CGFloat = 27
let leaveZone: CGFloat = 50
var state = "sketchy"

func run(_ cmd: String) {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", cmd]
    task.launch()
}

Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
    let mouseLocation = NSEvent.mouseLocation
    // Screens can overlap in Y when displays have different heights or are
    // offset vertically; `first(where:)` would pick whichever screen comes
    // first and measure from the wrong top edge. Instead, find the screen
    // whose horizontal range contains the cursor and use its own top.
    guard let screen = NSScreen.screens.first(where: {
        mouseLocation.x >= $0.frame.minX && mouseLocation.x <= $0.frame.maxX
    }) else { return }
    let mouseY = screen.frame.maxY - mouseLocation.y

    if state == "sketchy" && mouseY <= triggerZone {
        run("yabai -m config menubar_opacity 1.0; sketchybar --bar hidden=on")
        state = "native"
    } else if state == "native" && mouseY > leaveZone {
        run("yabai -m config menubar_opacity 0.0; sketchybar --bar hidden=off")
        state = "sketchy"
    }
}

RunLoop.main.run()
