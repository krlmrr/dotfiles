import AppKit
import Foundation

// Regression tests for menubar-toggle. The bug this guards against has been
// reintroduced repeatedly (5d2d929, fc3383f, acaf154): the cursor loop stops
// evaluating and strands the bar hidden until the cursor lands somewhere that
// happens to resolve.

let bounds = CGDisplayBounds(CGMainDisplayID())
let runClickTest = CommandLine.arguments.contains("--with-click")
var failures = 0
var skipped = 0

func shell(_ cmd: String) -> String {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", cmd]
    let pipe = Pipe()
    task.standardOutput = pipe
    try? task.run()
    task.waitUntilExit()
    return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? "?"
}

func barHidden() -> String {
    shell("sketchybar --query bar 2>/dev/null | jq -r .hidden")
}

// CG coords (origin top-left), the same space warp() uses.
func cursorCG() -> CGPoint {
    CGEvent(source: nil)?.location ?? CGPoint(x: -99999, y: -99999)
}

func warp(_ x: CGFloat, _ y: CGFloat) {
    CGWarpMouseCursorPosition(CGPoint(x: x, y: y))
    CGAssociateMouseAndMouseCursorPosition(1)
}

func cursorHeld(_ x: CGFloat, _ y: CGFloat) -> Bool {
    let here = cursorCG()
    return abs(here.x - x) <= 4 && abs(here.y - y) <= 4
}

func report(_ mark: String, _ label: String, _ detail: String) {
    print("  [\(mark)] \(label.padding(toLength: 44, withPad: " ", startingAt: 0))\(detail)")
}

// A check only means something if the cursor stayed where it was put. Real mouse
// input overrides the warp and would otherwise score a bogus PASS against whatever
// the bar already happened to be doing.
func check(_ label: String, x: CGFloat, y: CGFloat, expect: String) {
    for attempt in 1...4 {
        warp(x, y)
        Thread.sleep(forTimeInterval: 0.7)
        guard cursorHeld(x, y) else {
            if attempt == 4 { skipped += 1; report("SKIP", label, "mouse in use") }
            continue
        }
        let got = barHidden()
        guard cursorHeld(x, y) else {
            if attempt == 4 { skipped += 1; report("SKIP", label, "mouse in use") }
            continue
        }
        if got != expect { failures += 1 }
        report(got == expect ? "PASS" : "FAIL", label, "expect hidden=\(expect) got=\(got)")
        return
    }
}

func checkDesyncRecovery() {
    let label = "desync self-heals"
    // Establish the starting state rather than requiring it, so an earlier skip
    // that left the bar hidden doesn't cascade into a skip here too.
    warp(bounds.midX, bounds.midY)
    Thread.sleep(forTimeInterval: 0.8)
    for _ in 1...6 {
        if barHidden() == "off" { break }
        Thread.sleep(forTimeInterval: 0.5)
    }
    guard cursorHeld(bounds.midX, bounds.midY), barHidden() == "off" else {
        skipped += 1
        report("SKIP", label, "could not reach a clean starting state")
        return
    }
    _ = shell("sketchybar --bar hidden=on")
    for step in 1...12 {
        Thread.sleep(forTimeInterval: 0.5)
        guard cursorHeld(bounds.midX, bounds.midY) else {
            skipped += 1
            report("SKIP", label, "mouse in use")
            return
        }
        if barHidden() == "off" {
            report("PASS", label, String(format: "recovered in ~%.1fs", Double(step) * 0.5))
            return
        }
    }
    failures += 1
    report("FAIL", label, "still hidden after 6s")
}

// Park the cursor and wait for the bar to reach `expect`, retrying through mouse
// interference. Returns nil when the cursor would not stay put, so callers can
// distinguish that from the bar genuinely not following.
func settle(_ x: CGFloat, _ y: CGFloat, expect: String) -> Bool? {
    for _ in 1...4 {
        warp(x, y)
        Thread.sleep(forTimeInterval: 0.8)
        guard cursorHeld(x, y) else { continue }
        if barHidden() == expect, cursorHeld(x, y) { return true }
        if cursorHeld(x, y) { return false }
    }
    return nil
}

func checkClickRestore() {
    let label = "click below bar restores"
    let clickY: CGFloat = 45
    switch settle(bounds.midX, 2, expect: "on") {
    case nil: skipped += 1; report("SKIP", label, "mouse in use"); return
    case false: failures += 1; report("FAIL", label, "bar never hid to begin with"); return
    default: break
    }
    switch settle(bounds.midX, clickY, expect: "on") {
    case nil: skipped += 1; report("SKIP", label, "mouse in use"); return
    case false: failures += 1; report("FAIL", label, "left native before the click"); return
    default: break
    }
    let point = CGPoint(x: bounds.midX, y: clickY)
    CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)?
        .post(tap: .cghidEventTap)
    Thread.sleep(forTimeInterval: 0.05)
    let observed = NSEvent.pressedMouseButtons & 0x1 != 0
    CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)?
        .post(tap: .cghidEventTap)
    guard observed else {
        skipped += 1
        report("SKIP", label, "synthetic click never reached the system")
        return
    }
    for step in 1...5 {
        Thread.sleep(forTimeInterval: 0.4)
        if barHidden() == "off" {
            report("PASS", label, String(format: "restored in ~%.1fs", Double(step) * 0.4))
            return
        }
    }
    failures += 1
    report("FAIL", label, "still hidden after the click")
}

guard shell("pgrep -x menubar-toggle").isEmpty == false else {
    print("menubar-toggle is not running; nothing to test")
    exit(2)
}

print("display \(Int(bounds.width))x\(Int(bounds.height)), \(NSScreen.screens.count) screen(s)")
print("")

check("away from the bar", x: bounds.midX, y: bounds.midY, expect: "off")
check("into the bar", x: bounds.midX, y: 2, expect: "on")
check("leaving the bar restores", x: bounds.midX, y: bounds.midY, expect: "off")
check("top-right corner triggers", x: bounds.maxX - 1, y: 0, expect: "on")
check("leaving top-right restores", x: bounds.midX, y: bounds.midY, expect: "off")
check("top-left corner triggers", x: bounds.minX, y: 0, expect: "on")
check("leaving top-left restores", x: bounds.midX, y: bounds.midY, expect: "off")
check("bottom-right does not latch", x: bounds.maxX - 1, y: bounds.maxY - 1, expect: "off")
check("bottom-left does not latch", x: bounds.minX, y: bounds.maxY - 1, expect: "off")
// The band only holds what it inherits, so enter the bar before asserting it holds.
check("re-enter the bar", x: bounds.midX, y: 2, expect: "on")
check("hysteresis band holds native", x: bounds.midX, y: 40, expect: "on")
check("past leaveZone releases", x: bounds.midX, y: 80, expect: "off")

checkDesyncRecovery()

if runClickTest {
    checkClickRestore()
} else {
    print("  [----] click below bar restores               skipped (pass --with-click)")
}

warp(bounds.midX, bounds.midY)
print("")
if skipped > 0 {
    print("\(skipped) skipped — cursor was in use; rerun for a complete result")
}
print(failures == 0 ? "NO FAILURES" : "\(failures) FAILED")
exit(failures == 0 && skipped == 0 ? 0 : 1)
