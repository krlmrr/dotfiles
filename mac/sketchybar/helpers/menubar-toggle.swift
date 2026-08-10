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
var mouseWasDown = false

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

// Expanded by 1px because contains() uses half-open intervals and excludes maxY,
// where the cursor sits whenever it's in the menu bar (5d2d929); matching X alone
// (fc3383f) traded that for measuring the distance off an overlapping screen's top
// edge. Falls back to the nearest screen so an unresolvable point can't return nil
// and freeze the state machine with the bar hidden.
func screenUnderCursor(_ point: NSPoint) -> NSScreen? {
    if let hit = NSScreen.screens.first(where: {
        $0.frame.insetBy(dx: -1, dy: -1).contains(point)
    }) {
        return hit
    }
    return NSScreen.screens.min(by: {
        distanceSquared(point, $0.frame) < distanceSquared(point, $1.frame)
    })
}

func distanceFromTop(_ point: NSPoint) -> CGFloat? {
    guard let screen = screenUnderCursor(point) else { return nil }
    return screen.frame.maxY - point.y
}

// nil inside the hysteresis band, so neither caller forces a change there.
func unambiguousState(_ distance: CGFloat) -> String? {
    if distance <= triggerZone { return "native" }
    if distance > leaveZone { return "sketchy" }
    return nil
}

// Ask yabai (off the main thread) whether the focused window is native-fullscreen,
// then flip sketchybar/menubar on any transition. Never blocks the cursor loop.
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
            guard let distance = distanceFromTop(NSEvent.mouseLocation),
                  let want = unambiguousState(distance) else { return }
            if (hidden == "on") != (want == "native") {
                want == "native" ? showNative() : showSketchy()
            } else {
                state = want
            }
        }
    }
}

func pollCursor() {
    let mouseDown = NSEvent.pressedMouseButtons & 0x1 != 0
    let clicked = mouseDown && !mouseWasDown
    mouseWasDown = mouseDown

    // In native fullscreen macOS owns the menu bar (auto-hide + hover reveal);
    // pause the cursor toggle so it can't pop sketchybar back over the app.
    if fullscreen { return }

    guard let distance = distanceFromTop(NSEvent.mouseLocation) else { return }

    // A click below the bar is the user reaching for a window title bar, not the
    // menu, so give the bar back immediately instead of waiting to clear leaveZone.
    if clicked, state == "native", distance >= triggerZone {
        showSketchy()
        return
    }

    guard let want = unambiguousState(distance), want != state else { return }
    want == "native" ? showNative() : showSketchy()
}

// Leaving the bar hidden would strand the user with no status bar, so restore it
// synchronously — run() is fire-and-forget and would race the exit.
func restoreAndExit() -> Never {
    _ = capture("yabai -m config menubar_opacity 0.0; sketchybar --bar hidden=off")
    exit(0)
}

func repeatingTimer(_ interval: TimeInterval, _ handler: @escaping () -> Void) -> DispatchSourceTimer {
    let timer = DispatchSource.makeTimerSource(queue: .main)
    timer.schedule(deadline: .now() + interval, repeating: interval)
    timer.setEventHandler(handler: handler)
    timer.resume()
    return timer
}

func trapSignal(_ sig: Int32) -> DispatchSourceSignal {
    signal(sig, SIG_IGN)
    let source = DispatchSource.makeSignalSource(signal: sig, queue: .main)
    source.setEventHandler { restoreAndExit() }
    source.resume()
    return source
}

// Start from a known state rather than inheriting whatever the last run left.
showSketchy()

// DispatchSourceTimer rather than Timer: NSTimer gets coalesced well below its
// requested rate under load (measured ~24Hz for 1/60s), which stretched every
// interval derived from it.
let signalSources = [trapSignal(SIGTERM), trapSignal(SIGINT)]
let timers = [
    repeatingTimer(1.0 / 60.0, pollCursor),
    repeatingTimer(1.0 / 3.0, refreshFullscreen),
    repeatingTimer(2.0, reconcile),
]

RunLoop.main.run()
