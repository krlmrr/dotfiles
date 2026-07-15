import AppKit
import Foundation

// Trigger anywhere the sketchybar bar is drawn, not just the top few pixels —
// otherwise hovering the bar below ~10px (e.g. the right-side items) never
// reveals the native menu bar. Matches sketchybarrc's bar: height 24 + y_offset 3.
let triggerZone: CGFloat = 27
let leaveZone: CGFloat = 50
let fullscreenCheckEvery = 20   // ~3x/sec (60Hz / 20); fullscreen changes are coarse
var state = "sketchy"
var fullscreen = false
var checking = false
var tick = 0

func run(_ cmd: String) {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", cmd]
    task.launch()
}

// Ask yabai (off the main thread) whether the focused window is native-fullscreen,
// then flip sketchybar/menubar on any transition. Never blocks the 60Hz loop.
func refreshFullscreen() {
    if checking { return }
    checking = true
    DispatchQueue.global(qos: .utility).async {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c",
            "yabai -m query --windows 2>/dev/null | jq -e 'any(.[]; .[\"has-focus\"]==true and .[\"is-native-fullscreen\"]==true)' >/dev/null 2>&1 && echo 1 || echo 0"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "0"
        let nowFull = (out == "1")
        DispatchQueue.main.async {
            checking = false
            guard nowFull != fullscreen else { return }
            fullscreen = nowFull
            if fullscreen {
                // Fullscreen: hide sketchybar. Keep the native bar opaque so macOS's
                // own fullscreen auto-hide/reveal-on-hover shows the real menu bar.
                run("yabai -m config menubar_opacity 1.0; sketchybar --bar hidden=on")
            } else {
                // Back to normal: sketchybar shown, native bar transparent again.
                run("yabai -m config menubar_opacity 0.0; sketchybar --bar hidden=off")
                state = "sketchy"
            }
        }
    }
}

Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
    tick += 1
    if tick % fullscreenCheckEvery == 0 { refreshFullscreen() }

    // In native fullscreen macOS owns the menu bar (auto-hide + hover reveal);
    // pause the cursor toggle so it can't pop sketchybar back over the app.
    if fullscreen { return }

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
