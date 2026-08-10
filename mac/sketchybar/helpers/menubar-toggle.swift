import AppKit
import Foundation

// Trigger anywhere the sketchybar bar is drawn, not just the top few pixels —
// otherwise hovering the bar below ~10px (e.g. the right-side items) never
// reveals the native menu bar. Matches sketchybarrc's bar: height 24 + y_offset 3.
let triggerZone: CGFloat = 27
let leaveZone: CGFloat = 50
var state = "sketchy"
var fullscreen = false
var checking = false
var reconciling = false

func run(_ cmd: String) {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", cmd]
    task.launch()
}

func capture(_ cmd: String) -> String {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", cmd]
    let pipe = Pipe()
    task.standardOutput = pipe
    try? task.run()
    task.waitUntilExit()
    return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

func showNative() {
    run("yabai -m config menubar_opacity 1.0; sketchybar --bar hidden=on")
    state = "native"
}

func showSketchy() {
    run("yabai -m config menubar_opacity 0.0; sketchybar --bar hidden=off")
    state = "sketchy"
}

func distanceSquared(_ point: NSPoint, _ rect: NSRect) -> CGFloat {
    let horizontal = max(rect.minX - point.x, 0, point.x - rect.maxX)
    let vertical = max(rect.minY - point.y, 0, point.y - rect.maxY)
    return horizontal * horizontal + vertical * vertical
}

// Bounds are inclusive because contains/NSMouseInRect exclude maxY, where the
// cursor sits whenever it's in the menu bar (5d2d929). Matching X alone (fc3383f)
// traded that for measuring mouseY off an overlapping screen's top edge. Falls back
// to the nearest screen so an unresolvable point can't return nil and freeze the
// state machine with the bar hidden.
func screenUnderCursor(_ point: NSPoint) -> NSScreen? {
    if let hit = NSScreen.screens.first(where: {
        point.x >= $0.frame.minX && point.x <= $0.frame.maxX &&
        point.y >= $0.frame.minY && point.y <= $0.frame.maxY
    }) {
        return hit
    }
    return NSScreen.screens.min(by: {
        distanceSquared(point, $0.frame) < distanceSquared(point, $1.frame)
    })
}

// nil inside the hysteresis band, so neither caller forces a change there.
func unambiguousState(_ point: NSPoint) -> String? {
    guard let screen = screenUnderCursor(point) else { return nil }
    let mouseY = screen.frame.maxY - point.y
    if mouseY <= triggerZone { return "native" }
    if mouseY > leaveZone { return "sketchy" }
    return nil
}

// Ask yabai (off the main thread) whether the focused window is native-fullscreen,
// then flip sketchybar/menubar on any transition. Never blocks the 60Hz loop.
func refreshFullscreen() {
    if checking { return }
    checking = true
    DispatchQueue.global(qos: .utility).async {
        let out = capture(
            "yabai -m query --windows 2>/dev/null | jq -e 'any(.[]; .[\"has-focus\"]==true and .[\"is-native-fullscreen\"]==true)' >/dev/null 2>&1 && echo 1 || echo 0")
        let nowFull = (out == "1")
        DispatchQueue.main.async {
            checking = false
            guard nowFull != fullscreen else { return }
            fullscreen = nowFull
            if fullscreen {
                // Fullscreen: hide sketchybar. Keep the native bar opaque so macOS's
                // own fullscreen auto-hide/reveal-on-hover shows the real menu bar.
                showNative()
            } else {
                // Back to normal: sketchybar shown, native bar transparent again.
                showSketchy()
            }
        }
    }
}

// `state` is only what we last asked for, and --reload or a lost fire-and-forget
// run() drifts it from reality; edge-triggered transitions never recover from that.
func reconcile() {
    if reconciling || fullscreen { return }
    reconciling = true
    DispatchQueue.global(qos: .utility).async {
        let hidden = capture("sketchybar --query bar 2>/dev/null | jq -r '.hidden' 2>/dev/null")
        DispatchQueue.main.async {
            reconciling = false
            guard hidden == "on" || hidden == "off", !fullscreen else { return }
            guard let want = unambiguousState(NSEvent.mouseLocation) else { return }
            if (hidden == "on") != (want == "native") {
                want == "native" ? showNative() : showSketchy()
            } else {
                state = want
            }
        }
    }
}

// Own timers, not ticks off the cursor loop: macOS coalesces the 1/60s timer to
// ~24Hz, which stretched tick-based intervals ~2.5x (reconcile fired at 5s, not 2s).
Timer.scheduledTimer(withTimeInterval: 1.0 / 3.0, repeats: true) { _ in
    refreshFullscreen()
}

Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
    reconcile()
}

Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
    // In native fullscreen macOS owns the menu bar (auto-hide + hover reveal);
    // pause the cursor toggle so it can't pop sketchybar back over the app.
    if fullscreen { return }

    guard let want = unambiguousState(NSEvent.mouseLocation), want != state else { return }
    want == "native" ? showNative() : showSketchy()
}

RunLoop.main.run()
