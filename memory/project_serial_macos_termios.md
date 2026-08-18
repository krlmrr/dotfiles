---
name: project_serial_macos_termios
description: macOS resets termios on open() — stty before opening a /dev/cu.* port is discarded and the line silently runs at 9600
metadata:
  type: project
---

On macOS, opening a `/dev/cu.*` port resets its termios settings, so any `stty`
run *before* the open is thrown away and the port silently falls back to 9600.
Symptom: total silence, or a baud-rate scan where every rate returns ~28-47%
printable bytes (random noise scores ~38%, since 100 of 256 byte values are
printable — real console output scores 95%+). The whole scan is meaningless
because every sample was actually taken at 9600.

Fix: configure via `termios` *after* `os.open()`, then assert the speed stuck.
Helper lives at `~/bt6/serial.py` (`open_port(dev, baud)` / `verify(fd)`).

This burned the 2026-08-17 session (misdiagnosed as a baud mismatch, then as a
failing adapter — neither held) and was re-tripped on 2026-08-18.

Companion check: before concluding anything from serial silence, run a loopback
probe (`~/bt6/lb.py`). If a distinctive string returns verbatim, the adapter's TX
is shorted to its own RX and the device under test is not in the circuit. Also
check for stale reader processes holding the port (`lsof /dev/cu.usbserial-0001`;
`~/bt6/*.pid` accumulate stale entries) — a leftover reader steals the bytes.

Console baud for the MT7988 boxes (BT6/BT8) is 115200. See [[feedback_no_sleep]],
[[feedback_stop_guessing]].
