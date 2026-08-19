---
name: project_box3_lightning
description: Box 3 took a lightning hit but boots fine — its serial "silence" was TX/RX reversed, not damage
metadata:
  type: project
---

"Box 3" among the router units took a lightning/surge hit ("not the good kind"),
but as of 2026-08-18 it **boots stock Asus firmware and runs normally** — the
main board survived. Do not treat it as dead.

The lightning was a red herring for a whole debugging session. Box 3 read as
totally silent on serial (UART pin idle high, zero bytes across a full power
cycle) and that was misread as surge damage. **The wires were TX/RX reversed** —
every reading was probing box 3's own RX pin, which idles high and never
transmits, a perfect impostor for a dead board.

Doctrine learned: reversed TX/RX is indistinguishable from a dead board from the
host side. Confirm orientation BEFORE reasoning about the board's health, and
don't let a dramatic backstory (lightning, power surge) raise the prior on
hardware death — it crowds out the boring explanation.

What the rig proved good along the way, all still valid: adapter TX+RX work
(loopback echoes verbatim), a jumper's continuity can be tested with no meter by
touching it to GND (4.5KB of noise = intact wire, ~2 bytes = broken), and 115200
is the console baud for these MT7988 boxes.

Stock Asus firmware uses serial as an **output-only kernel console** — a CR gets
no prompt, there is no getty. For an interactive prompt, interrupt U-Boot during
its `bootdelay=2` window (`~/bt6/uboot_break.py`) or enable SSH/telnet in the web
UI.

Still untested on box 3: Ethernet. Lightning typically enters via the WAN port,
so the ports are the most plausible casualty even though the SoC is fine.

Related: [[project_serial_macos_termios]].

## LAN ports "dead" = repeater/media-bridge mode, not damage (2026-08-18)

WAN tested fine while all LAN ports appeared dead. Not lightning damage and not
the switch. The serial console showed box 3 running in an AP-client mode:

- `wpa_cli -i apcli0 / apclix0 scan|disconnect` looping — `apcli*` interfaces
  exist only in repeater / media-bridge mode, stuck hunting a vanished upstream AP.
- `udhcpc_lan:: leasefail` — a DHCP *client* on LAN. A router serves DHCP there;
  only a bridged box tries to get a lease.

In those modes the port roles change and LAN stays unusable until the upstream
association succeeds, which it never does. Fix: factory reset (hold reset ~10s)
to return to router mode.

Note the kernel log showed NO switch or PHY errors — an earlier theory about the
`eth2` null MAC in U-Boot indicating an uninitialized switch was unsupported.

## Correction (2026-08-18, later): the LAN jacks really are dead

The repeater-mode explanation above does NOT account for the dead LAN ports.
Karl reported from the start that WAN worked and no LAN did; that direct report
was correct and I over-rode it with the apcli0/leasefail theory.

Evidence: in U-Boot (no Asus firmware running, so mode config is irrelevant) the
WAN jack negotiates a clean 1000baseT link, while LAN 1 gives
`status: inactive / media: autoselect (none)` — no PHY link at all, and U-Boot's
`ping` never puts a single ARP frame on the wire (confirmed by tcpdump on the Mac:
42 packets captured, all the Mac's own ARPs for its gateway, zero from box 3).

Caveat kept honest: U-Boot may hold the internal switch in reset, so "no link in
U-Boot" alone isn't proof of damage. But combined with the same symptom under
stock firmware, switch/PHY damage is now the leading explanation — and the
lightning finally has something it plausibly did explain.

Consequence: no Ethernet path to box 3 for TFTP. Transfers must go over serial
(`loady 0x44000000` + YMODEM at 115200).

Lesson: when the user reports hardware behaviour they have tested, treat it as
evidence and don't substitute a tidier theory for it.

## Root cause found: all four LAN PHYs fail analog calibration (2026-08-18)

Booted the OpenWrt BT6 initramfs from RAM on box 3 (YMODEM over serial, see
below) and the kernel log named the fault:

    MediaTek MT7988 PHY mt7530-0:00: cal_cycle failed: -110
    MediaTek MT7988 PHY mt7530-0:00: Calibration cycle timeout
    MediaTek MT7988 PHY mt7530-0:00: cal 4 failed
    MediaTek MT7988 PHY mt7530-0:00: probe ... failed with error -5

Identical for :01, :02, :03. The mt7530 switch MAC block is HEALTHY — the driver
reaches all four PHYs over MDIO and creates lan1..lan3 — but every PHY times out
in its analog calibration cycle, so none ever links.

Proven to be hardware, not the device tree, by comparison with yesterday's
`~/bt6/logs/bt6-p3-test.log` from a different unit on the same driver and same DTS
lineage (both show only lan1-3, so same DTS): there the PHYs bind cleanly
(`PHY [mt7530-0:01] driver [MediaTek MT7988 PHY] (irq=111)`) and `lan1: Link is
Up - 1Gbps/Full`. Same software calibrates fine elsewhere. **Flashing does not
fix box 3's LAN ports.**

All four failing identically at the same step implicates a SHARED analog resource
— common supply rail, reference clock, or the external precision resistor setting
PHY bias current — not four independently fried PHYs. Board-level repairable in
principle; not a firmware problem. (`mtk-xsphy: failed to get ref_clk(id-1)`
also appears earlier in the log.)

Box 3 remains useful: the WAN port is a separate MT7988 2.5GbE PHY and links
fine, and the radios work. An AP or wireless bridge needs one port — so box 3 can
be that, just never a router or switch.

## Serial transfer route that works (no Ethernet needed)

`~/bt6/ysend.py <file> "loady 0x44000000"` — self-contained YMODEM-1K sender
using `serial.open_port` (avoids the termios trap; do NOT hand a raw fd to `sz`).
12MB moves in ~1096s at a flat 11300 B/s, which is the 115200 ceiling. Verify
afterwards with `printenv filesize` (hex byte count) and `md.l 0x44000000 4`
(expect `edfe0dd0` = FIT magic byte-swapped). Then `bootm 0x44000000` runs it from
RAM, writing nothing.

Reach the U-Boot prompt with `~/bt6/uboot_break.py` (spams `4`, menu option 4)
during a power-cycle. Stock Asus firmware echoes serial input but runs no getty,
so there is no prompt until U-Boot or OpenWrt.

## Box 3 now runs OpenWrt from flash (2026-08-18)

Flashed successfully via sysupgrade. State after:

- rootfs `ubi0_5`, overlay `ubi0_6` (ubifs) — booting from flash, not RAM.
- `linux` volume 6,475,776 (was 68,059,136 stock).
- **nvram / Factory / Factory2 MD5s unchanged by the flash** and identical to the
  `flash/unit-C/` backups: `4a87273d…`, `04f767c0…`, `04f767c0…`. sysupgrade does
  not touch those volumes on this device.
- Image used: `openwrt-…-bt6-squashfs-sysupgrade.bin`, sha256 `f1c151b0…`
  (matches published sums). Stock upstream — does NOT include the lan3 DTS fix,
  which is moot here since box 3's LAN PHYs never calibrate.
- Benign noise in the log: `ubirmvol: cannot find UBI volume "rootfs"/"rootfs_data"`
  (nothing to remove pre-flash), `Watchdog does not have CARDRESET support`,
  `WARNING: CASN page check failed` (U-Boot NAND param page).

### The delivery route that worked, with no Ethernet

Box 3's radio joined the house Wi-Fi as a station and pulled the image over the
air — far faster than serial:

1. `iw phy phy0 interface add wlan0 type managed; ip link set wlan0 up`
2. wpa_supplicant conf in /tmp, `wpa_supplicant -B -i wlan0 -c /tmp/wpa.conf -Dnl80211`
3. `udhcpc -i wlan0`
4. **Delete OpenWrt's default `br-lan` 192.168.1.1/24** — it collides with the
   house 192.168.1.0/24 and wins the route, sending traffic out the dead LAN
   ports. `ip addr del 192.168.1.1/24 dev br-lan; ip link set br-lan down`.
   Without this the box cannot reach the LAN despite an active Wi-Fi lease.
5. `python3 -m http.server` on the Mac, `wget` on the box, verify sha256, then
   `sysupgrade -T` to validate and `sysupgrade -n` to write.

Also corrected: `phy0` reports `Radios: 0 1 2` — all three bands present. An
earlier worry that only one radio came up was wrong.

Still to do: configure the radios (OpenWrt ships them disabled) to make box 3 an
AP on the working WAN port.

## Box 1 (unit-A) mesh support installed (2026-08-18)

Box 1 was already flashed to the same OpenWrt snapshot as box 3
(`r0-1a77cc5`, `wpad-basic-mbedtls-2026.08.07~831364bf-r2`) and reachable
directly via SSH at 192.168.1.1 over the shared L2 segment on en7 (Mac at
192.168.1.210) — no serial adapter needed for this box, since it only needed a
package swap, not a flash.

Repeated the box-3 recipe over SSH instead of the serial console:
1. wlan0 station joins "Hey Siri!" (same SSID/psk as box 3), `udhcpc`, static
   resolv.conf (1.1.1.1/8.8.8.8) since udhcpc -q doesn't write one.
2. `apk update`, then `apk del wpad-basic-mbedtls` immediately followed by
   `apk add wpad-mesh-mbedtls` **in the same SSH session** — no gap where the
   box has no wpad binary (the box-3 attempt to pre-fetch and install from a
   local .apk file failed with `UNTRUSTED signature`; installing straight from
   the signed feed is the reliable path).
3. Tore down wlan0/wpa_supplicant afterward.

Box 2 (unit-B) still needs the same treatment — still stock Asus firmware as of
last check (only `ubi-linux-STOCK.bin` backed up, no OPENWRT backup), so it
needs the full flash procedure done for box 3 before this package swap applies.

Same wpad swap procedure should work identically for box 2 once it's on
OpenWrt: `apk del wpad-basic-mbedtls && apk add wpad-mesh-mbedtls` as one
session, over whatever link (WAN/LAN/Wi-Fi) is fastest to reach it.

## Box 2 mesh support installed (2026-08-18)

Box 2 was ALSO already on the same OpenWrt snapshot (`r0-1a77cc5`,
`wpad-basic-mbedtls`) despite `flash/unit-B/` only having a STOCK backup on
disk — that backup predates whenever box 2 got flashed, so don't infer a box's
current firmware state from the presence/absence of an OPENWRT backup file.
Always check the live box (SSH or serial) before assuming.

MAC bc:fc:e7:2f:84:54, reachable at 192.168.1.1 same as the others (each unit
defaults to that address on br-lan when alone on a segment). Same recipe as
box 1 applied verbatim (wlan0 join "Hey Siri!" -> apk del/add in one session ->
teardown). Installed and verified identically.

**All three boxes (1, 2, 3) now have wpad-mesh-mbedtls installed.** None have
mesh (802.11s) actually configured yet — that's still a uci wireless config
task, plus deciding the mesh ID/key and which radio carries the backhaul.

## Mesh (802.11s) configured on box 1 (2026-08-18)

Generated identity, saved to `~/bt6/mesh-credentials.env` (chmod 600, not
committed anywhere): mesh ID `OpenWrt-Mesh-4a1e2b`, SAE key
`DqaHLGRpdnNGIGDYSzuzQ7Jx`. Backhaul on radio2 (6GHz), channel 5, EHT80.

**Prerequisite discovered:** radio2's `country` was `'00'` (world regdomain) by
default, under which 6GHz is not permitted at all — `iw phy0 info` showed zero
6GHz frequencies. Setting `uci set wireless.radio2.country='US'` (then `wifi up
radio2`) is what makes the 5925-7125 MHz range and channels appear. Without this
step, mesh_id/key config on a 6GHz radio silently has no channel to sit on.
US 6GHz is LPI/indoor-only: 12 dBm max, NO-OUTDOOR tag in the reg rules.

uci config applied (per box, radio device name may differ — verify with
`uci show wireless.radioN.band` first):
    uci set wireless.radioN.country='US'
    uci set wireless.radioN.channel='5'
    uci set wireless.radioN.htmode='EHT80'
    uci set wireless.radioN.disabled='0'
    uci set wireless.mesh_radioN=wifi-iface
    uci set wireless.mesh_radioN.device='radioN'
    uci set wireless.mesh_radioN.mode='mesh'
    uci set wireless.mesh_radioN.mesh_id='OpenWrt-Mesh-4a1e2b'
    uci set wireless.mesh_radioN.encryption='sae'
    uci set wireless.mesh_radioN.key='DqaHLGRpdnNGIGDYSzuzQ7Jx'
    uci set wireless.mesh_radioN.network='lan'
    uci set wireless.mesh_radioN.mesh_fwding='1'
    uci commit wireless && wifi reload

Verified via `logread`: `phy0.2-mesh0` came up, `MESH-GROUP-STARTED
ssid="OpenWrt-Mesh-4a1e2b"`, bridged into br-lan (forwarding state). Same
config still needs applying to boxes 2 and 3, then confirm they peer with each
other (mesh neighbours show up via `iw dev <mesh-iface> mesh_peer_status` /
`iw dev <mesh-iface> station dump` once more than one node is up).

**Security note found in passing, not yet addressed:** dropbear logged `Auth
succeeded with blank password for 'root'` — no root password set (stock
first-boot OpenWrt state). Set one on all three before leaving them on the
network unattended.

## Box 3 set aside (2026-08-18)

Karl inspected the board visually and sees nothing obviously wrong, and isn't
concerned about pursuing a fix right now — deprioritized, not abandoned. Don't
push to re-open this without being asked.

Also newly discovered blocker if picked back up later: box 3's WAN port is
firewalled by OpenWrt's default config (WAN zone drops unsolicited inbound,
including ping/SSH) — so even with a DHCP lease from another box's router
function, it's unreachable over the network. Every prior network-shell
interaction with box 3 this session was actually over the SERIAL CONSOLE, not
SSH; box 3 has never been reached over the network at all. Re-adding the
USB-TTL serial adapter is the only clean way back in.

Mesh status as it stands: boxes 1 and 2 are confirmed peered and passing
traffic over the 6GHz backhaul (see the earlier mesh section). Box 3 never got
mesh configured.

## Box 2 converted to dumb AP (2026-08-18)

network.lan: proto static, ipaddr 192.168.1.2/24, gateway/dns 192.168.1.1 (box1).
dhcp.lan: ignore=1, dhcpv4/dhcpv6/ra=disabled. No longer claims .1 or runs its own
DHCP server, resolving the conflict with box1 once mesh-bridged. Config
verified live via SSH at 192.168.1.2 after reboot.

Box 1 stays at 192.168.1.1 as the real router/DHCP server, unchanged.

**Root cause of a long false alarm this session:** the Mac's dock enumerates the
SAME physical port as different macOS network services across replugs (en7,
a registered "Thunderbolt Ethernet Slot 0" service vs en13, unregistered) — and
BOTH sometimes show status:active simultaneously (one stale). Plain `ping` with
no interface binding silently goes out whichever interface macOS's routing
table currently prefers for the (ambiguous, overlaps-home-LAN) 192.168.1.0/24
subnet — sometimes the wrong one — producing a false "no reply" even when the
target is perfectly reachable. `sudo tcpdump -i en7 -nn` proved box2 was alive
and correctly configured (its own ARPs for gateway .1 were visible) the whole
time; only the Mac's own unbound ping was going out the wrong interface.
**Lesson: when ping to a box on this bench setup mysteriously fails despite a
good link, use `ping -b <iface>` (explicit interface bind) or tcpdump before
concluding the box itself is unreachable — don't trust unbound ping's interface
choice on this dual-subnet setup.** networksetup's manual-IP command also needs
the exact service name from `networksetup -listallnetworkservices` — the
hardware port label ("Thunderbolt Ethernet Slot 0, Port 2") and the service
name ("Thunderbolt Ethernet Slot 0") differ.

## Mesh + dumb-AP topology confirmed working end to end (2026-08-18)

After power-cycling box 1 (with box 2 already converted to dumb AP), the mesh
re-peered automatically within seconds: `plink: ESTAB`, -14dBm, ~2Gbps
bidirectional (EHT-MCS 12/13, 80MHz). Box 2 pings box 1 (192.168.1.1) through
the bridge with 0% loss, confirming box2's static-IP/gateway config correctly
routes through box1 rather than conflicting with it. This is the target
topology working as intended: box1 = router/DHCP, box2 = dumb AP peered over
6GHz mesh. Box 3 remains outside this (deprioritized, see above).

## Reproducible bug: box1 breaks IPv4 entirely when moved to 10.10.10.x (2026-08-18)

Confirmed TWICE, identically: setting `network.lan.ipaddr='10.10.10.1'` (from
the default 192.168.1.1) + `uci commit network` + reboot leaves box1 with:
- IPv6 working fine (router advertisement, DNS via RA all reach the Mac)
- IPv4 completely dead: ARP resolves correctly (kernel-level, confirms the
  interface really holds the new address) but ICMP ping, SSH, LuCI (http/https),
  and DHCPv4 all get no response at all. Not an interface-selection artifact on
  the Mac side — confirmed via `sudo tcpdump` showing the ARP reply arrive
  correctly, followed by zero ICMP replies to real echo requests.
- A factory reset (external reset button, ~10s) reliably restores it to a
  working 192.168.1.1 default both times this was hit.

Root cause NOT diagnosed — no serial access to box1 was available either time
(user declined reconnecting it). Suspect dnsmasq or firewall(fw4) choking on
the address change specifically, since IPv6 (odhcpd, a separate daemon) is
unaffected while IPv4 (dnsmasq + presumably nftables input rules) is fully
dead. Untested whether ANY non-192.168.1.x range triggers it, or specifically
10.10.10.0/24.

**Decision: do not retry moving box1 off 192.168.1.1.** Both boxes stay on
192.168.1.x. If revisited later, only attempt with serial connected to box1 so
the actual failure can be observed (dmesg, service status, uci) instead of
inferring from outside.

## Custom BT6 firmware built successfully via local Docker (2026-08-18/19)

After tracing three separate real bugs, a from-scratch OpenWrt build for the
BT6 succeeded locally (no GitHub Actions wait) via Docker/OrbStack on Apple
Silicon. Output in `~/bt6/docker-build/out/`:
`openwrt-mediatek-filogic-asus_zenwifi-bt6-squashfs-sysupgrade.bin` (14M),
matching `-factory.bin` (12M), both sha256-verified against `sha256sums`.
Confirmed baked in: `kmod-tun-6.18.44-r1.apk` (built against the exact running
kernel), `wpad-mesh-mbedtls`, `cgi-io`. `tailscale` deliberately excluded (see
below) - not baked in.

### The three real bugs hit, in order, all worth remembering for next time

1. **OpenWrt's build refuses to run `configure` as root.** GitHub's CI runner
   uses a non-root user; a bare `ubuntu:24.04` container runs everything as
   root by default. Fix: create an unprivileged `builder` user, `chown -R` the
   work tree, run every OpenWrt command (`feeds`, `make`) via `sudo -u builder`.
   Symptom: `tools/tar` host-tool build fails with "you should not run
   configure as root".

2. **Ubuntu's generic `awk` can silently resolve to `mawk` instead of `gawk`**
   even after `apt-get install gawk` succeeds, if something else in the same
   transaction re-registers the alternative. OpenWrt's feed scanner
   (`include/scan.awk`) uses gawk's `asort()` extension; under mawk it fails
   with `function asort never defined` - but only during feed
   indexing/scanning, and the FAILURE ITSELF can be silent (no error surfaces
   up through `feeds update -a`'s output for the specific feed it broke).
   Fix: `update-alternatives --set awk /usr/bin/gawk` explicitly, don't trust
   install order.

3. **The real, hardest-to-find one: `feeds update` doesn't force re-indexing
   a feed whose git commit hasn't changed.** The very first (mawk-broken) run
   produced an empty `feeds/packages.index` (0 lines) for the "packages" feed.
   Every subsequent retry reused that same git clone (unchanged HEAD), so
   `feeds update -a` silently skipped re-scanning it and kept serving the
   stale empty index - even after the awk bug was fixed. Symptom: `feeds
   install -a` reports "Installing all packages from feed packages." (looks
   successful, exit code 0) but creates zero symlinks under
   `package/feeds/packages/`, and any package from that feed (we hit
   `cgi-io`, a hard dependency of `luci-base`) fails at the very end of a
   FULL build with `ERROR: unable to select packages: cgi-io (no such
   package)` - a maximally expensive place to discover a feed-indexing bug.
   Fix: `rm feeds/packages.index` (and any other affected `feeds/<name>.index`)
   to force a real re-scan; compare index line counts against a known-good
   feed (`luci.index` had 70k+ lines; the broken `packages.index` had 0) as a
   fast health check.

### tailscale deliberately NOT baked in - real upstream ARM64 limitation

Building `tailscale` requires bootstrapping Go from source, which requires
`golang-bootstrap`. That package's `BOOTSTRAP_GO_VALID_OS_ARCH` list (its
legacy C-based bootstrap compiler, distinct from the modern Go toolchain's own
`HOST_GO_VALID_OS_ARCH` which DOES include linux/arm64) only lists
`linux/386`, `linux/amd64`, `linux/arm` - never `linux/arm64`. This is a real,
long-standing Go/OpenWrt limitation for ARM64 BUILD HOSTS (irrelevant to the
TARGET architecture) - GitHub's x86_64 CI runners never hit it, which is why
building this same repo via its `.github/workflows/build.yml` would not need
this workaround. Since `kmod-tun` has no such issue and is the *only* thing
`tailscale`'s LuCI install ever reported missing, `apk add tailscale` on the
live device after flashing this build should now succeed on its own - it's a
plain userspace binary with no kernel-version dependency, it only needed the
kernel module to exist at runtime.

Still to do: flash box1 (or box2) with this new image, confirm LAN ports and
mesh still work post-flash (should be identical since dts/config.seed for
those didn't change), then `apk add tailscale` live and confirm it installs
cleanly this time.

## Box 2 sysupgrade over SSH reliably fails; LuCI upload is the fix (2026-08-19)

Flashing the new custom image onto box 2 via SSH-triggered `sysupgrade` failed
identically on every attempt (5+ tries): mesh-relayed, direct-wired, `&`
backgrounded on the remote shell, and even `setsid sysupgrade ...` (genuine
session detachment) - all produced the same
`Command failed: ubus call system sysupgrade {...} (Connection failed)`,
always right after `Commencing upgrade. Closing all shell sessions.` A live
`logread -f` capture showed the actual mechanism: `dropbear[1624]: Early exit:
Terminated by signal` - the SSH daemon itself gets killed as part of that
step, and whatever spawned `sysupgrade` dies with it before the `do_stage2`
handoff completes. `setsid` did not fix it, meaning the kill isn't purely a
session/process-group signal - likely a broader by-name/PID-file service stop
that catches the sysupgrade invocation regardless of its session.

Box 1's flash succeeded because Karl did it manually through **LuCI's own web
upload** (System > Backup/Flash Firmware), not over SSH - that path isn't tied
to a killable SSH session at all and never hits this race.

**Lesson: don't try to trigger `sysupgrade` on this device over SSH. Use
LuCI's upload UI.** Every SSH-triggered attempt left box 2 in a recoverable
state though (config/mesh/services all intact after each failed attempt, one
required a manual power-cycle after a raw manual `ubus call system sysupgrade`
test left dropbear/services down without the script's own reboot-on-failure
fallback - avoid raw manual ubus calls entirely, they lack that safety net).

Still to do: flash box 2 via LuCI upload with
`~/bt6/docker-build/out/openwrt-mediatek-filogic-asus_zenwifi-bt6-squashfs-sysupgrade.bin`
(same file already confirmed working on box 1) whenever Karl gets to it.
