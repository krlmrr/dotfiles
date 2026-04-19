import AppKit
import Foundation

let triggerZone: CGFloat = 10
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
    guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) else { return }
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
