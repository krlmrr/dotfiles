// Posts macOS's own "Switch to Desktop N" shortcut (ctrl+N) with the modifier
// flags FORCED to control only.
//
// Why this exists: skhd fires its command while the triggering chord's
// modifiers are still physically held. Anything that posts ctrl+N normally —
// osascript's `key code N using control down` included — has the real modifier
// state merged in, so macOS sees ctrl+shift+N, matches no shortcut, and the
// view never follows the window. CGEventSetFlags overrides that.
//
// yabai can move a window across spaces with SIP on, but cannot focus a space
// (`space --focus` needs the scripting addition SIP blocks), hence letting
// macOS do the switching via its own shortcut.
//
// Usage: space-follow <1-9|left|right>
// Build: swiftc -O space-follow.swift -o space-follow

import CoreGraphics
import Foundation

// Keycodes for the number row and arrows. macOS binds ctrl+1..9 to
// "Switch to Desktop 1..9" (symbolichotkeys 118-126) and ctrl+left/right to
// "Move left/right a space" (79/81).
let keycodes: [String: CGKeyCode] = [
    "1": 18, "2": 19, "3": 20, "4": 21, "5": 23,
    "6": 22, "7": 26, "8": 28, "9": 25,
    "left": 123, "right": 124,
]

guard CommandLine.arguments.count == 2,
      let key = keycodes[CommandLine.arguments[1]] else {
    FileHandle.standardError.write("usage: space-follow <1-9|left|right>\n".data(using: .utf8)!)
    exit(2)
}

guard let src = CGEventSource(stateID: .hidSystemState) else { exit(1) }

for isDown in [true, false] {
    guard let e = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: isDown) else { exit(1) }
    e.flags = .maskControl // the whole point: drop the held shift
    e.post(tap: .cghidEventTap)
}
