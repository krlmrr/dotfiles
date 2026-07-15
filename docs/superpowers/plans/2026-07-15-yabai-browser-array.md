# yabai Browser Array Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generalize the hardcoded `Zen` top-left role into a `BROWSER_APPS` array so any browser (Zen / Google Chrome / Safari / Arc) is a first-class occupant of the top-left slot, ending the constant destructive rebuilds.

**Architecture:** Mirror the existing `EDITOR_APPS` pattern. A newline-delimited `BROWSER_APPS` list generates a jq predicate (`browser_sel`) and a signal regex (`BROWSER_RE`). A new `browser_id()` helper returns the single slot occupant. `external_correct()`, `place_editors()`, `adopt()`, and the browser `window_created` signal all switch from Zen-specific lookups to the browser set. Single browser owns the slot at a time ("single browser only").

**Tech Stack:** POSIX sh, `yabai -m query`/`jq`, macOS LaunchAgent.

## Global Constraints

- Scope is `mac/yabai/yabairc` ONLY. No other file changes.
- `mac/yabai/yabairc` is **symlinked** (per CLAUDE.md delivery table) — edits are live; no build step. A running-config change requires `yabai --restart-service` to take effect.
- App names must match yabai's `.app` string exactly: `Zen`, `Google Chrome`, `Safari`, `Arc`.
- `BROWSER_APPS` is **newline-delimited**, NOT space-split — `Google Chrome` contains a space.
- Do not alter trio geometry, warp/verify/repair machinery, space 2 float, PiP handling, or `LAPTOP_W`/`LAPTOP_H`.
- Never mutate the live layout during verification except the single final reload (Task 7).
- Golden layout (user-confirmed correct) is saved at
  `/private/tmp/claude-501/-Users-karlm-Code-dotfiles/6ae1db66-9e6e-461e-bdc8-58ffd9108122/scratchpad/golden_layout.txt`:
  `Ghostty x=12 y=916`, `Code x=1605 y=37`, `Google Chrome x=12 y=37` on space 3.

---

### Task 1: Browser array + generated selectors

**Files:**
- Modify: `mac/yabai/yabairc` (insert after the `EDITOR_RE=...` line, currently line 38)

**Interfaces:**
- Consumes: nothing.
- Produces: shell vars `BROWSER_APPS` (newline list), `browser_sel` (jq predicate string, e.g. `(.app=="Zen" or .app=="Google Chrome" or …)`), `BROWSER_RE` (regex `^(Zen|Google Chrome|Safari|Arc)$`). Built on every invocation before the dispatch `case`, exactly like `editor_sel`/`EDITOR_RE`.

- [ ] **Step 1: Write the failing test** — a standalone script that runs only the generation snippet and asserts the outputs.

```sh
# /private/tmp/.../scratchpad/test_browser_array.sh
BROWSER_APPS='Zen
Google Chrome
Safari
Arc'
browser_sel=""; browser_alt=""
while IFS= read -r a; do
  [ -n "$a" ] || continue
  browser_sel="$browser_sel${browser_sel:+ or }.app==\"$a\""
  browser_alt="$browser_alt${browser_alt:+|}$a"
done <<EOF
$BROWSER_APPS
EOF
browser_sel="($browser_sel)"
BROWSER_RE="^($browser_alt)\$"

exp_sel='(.app=="Zen" or .app=="Google Chrome" or .app=="Safari" or .app=="Arc")'
exp_re='^(Zen|Google Chrome|Safari|Arc)$'
[ "$browser_sel" = "$exp_sel" ] && [ "$BROWSER_RE" = "$exp_re" ] \
  && echo PASS || { echo "FAIL"; echo "sel=$browser_sel"; echo "re=$BROWSER_RE"; exit 1; }
```

- [ ] **Step 2: Run it to confirm the snippet is correct**

Run: `sh /private/tmp/claude-501/-Users-karlm-Code-dotfiles/6ae1db66-9e6e-461e-bdc8-58ffd9108122/scratchpad/test_browser_array.sh`
Expected: `PASS`

- [ ] **Step 3: Insert the block into `yabairc`** immediately after the `EDITOR_RE="^(...)$"` line:

```sh
# The browser set — whichever is open owns the top-left slot ("single browser
# only": the first open one is the slot; extras get adopted). Multi-word names
# (e.g. "Google Chrome") mean this list is NEWLINE-delimited, not space-split
# like EDITOR_APPS. browser_sel (jq) and BROWSER_RE (signal regex) are generated.
BROWSER_APPS='Zen
Google Chrome
Safari
Arc'
browser_sel=""; browser_alt=""
while IFS= read -r a; do
  [ -n "$a" ] || continue
  browser_sel="$browser_sel${browser_sel:+ or }.app==\"$a\""
  browser_alt="$browser_alt${browser_alt:+|}$a"
done <<EOF
$BROWSER_APPS
EOF
browser_sel="($browser_sel)"
BROWSER_RE="^($browser_alt)\$"
```

- [ ] **Step 4: Syntax-check the whole file**

Run: `sh -n mac/yabai/yabairc && echo OK`
Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add mac/yabai/yabairc
git commit -m "yabai: define BROWSER_APPS array + generated browser_sel/BROWSER_RE"
```

---

### Task 2: `browser_id()` helper

**Files:**
- Modify: `mac/yabai/yabairc` (add helper next to `win_id()`, ~line 55)

**Interfaces:**
- Consumes: `browser_sel` (Task 1).
- Produces: `browser_id()` — echoes the id of the first STANDARD, non-PiP browser window in query order (empty if none). This is the top-left slot occupant.

- [ ] **Step 1: Add the helper** after `win_id()`:

```sh
browser_id() {  # id of first STANDARD browser window (the top-left slot occupant;
                # skips phantoms and the "Picture-in-Picture" popout)
  yabai -m query --windows 2>/dev/null \
    | jq -r ".[]|select($browser_sel and .subrole==\"AXStandardWindow\" and .title!=\"Picture-in-Picture\")|.id" | head -1
}
```

- [ ] **Step 2: Syntax-check**

Run: `sh -n mac/yabai/yabairc && echo OK`
Expected: `OK`

- [ ] **Step 3: Read-only behavioral test against live windows** — Chrome is currently the top-left browser, so `browser_id` (via the same jq) must return Chrome's id and it must match the `Google Chrome` window on space 3.

Run:
```sh
sel='(.app=="Zen" or .app=="Google Chrome" or .app=="Safari" or .app=="Arc")'
bid=$(yabai -m query --windows | jq -r ".[]|select($sel and .subrole==\"AXStandardWindow\" and .title!=\"Picture-in-Picture\")|.id" | head -1)
app=$(yabai -m query --windows --window "$bid" | jq -r '.app')
echo "browser_id=$bid app=$app"
```
Expected: `app=Google Chrome` (non-empty id).

- [ ] **Step 4: Commit**

```bash
git add mac/yabai/yabairc
git commit -m "yabai: add browser_id() helper for the top-left slot occupant"
```

---

### Task 3: Generalize `external_correct()` — the core fix

**Files:**
- Modify: `mac/yabai/yabairc` — replace the `external_correct()` body (currently ~lines 125-144)

**Interfaces:**
- Consumes: `browser_sel`, `editor_sel`.
- Produces: `external_correct <space>` — same contract (exit 0 when layout correct), but the top-left role is `$browser` (any browser) instead of `$zen`.

- [ ] **Step 1: Read-only test FIRST — prove current code reports WRONG** for the golden layout (regression demonstration). Run the CURRENT (Zen-hardcoded) predicate against live space 3:

Run:
```sh
yabai -m query --windows --space 3 | jq -e '
    (map(select(.subrole=="AXStandardWindow" and .title!="Picture-in-Picture"))) as $w
  | ($w|map(select(.app=="Zen"))|first) as $zen
  | ($w|map(select(.app=="Zed" or .app=="Code"))|first) as $ed
  | ($w|map(select(.app=="Ghostty"))|first) as $gho
  | ([$zen,$ed,$gho]|map(select(.!=null))|length) as $n
  | if $n<=1 then true elif $ed then ($zen and $gho) else ($zen and $gho) end
' >/dev/null && echo "reports CORRECT" || echo "reports WRONG"
```
Expected: `reports WRONG` (Zen absent → the bug).

- [ ] **Step 2: Replace `external_correct()`** with the browser-generalized version:

```sh
external_correct() {
  yabai -m query --windows --space "$1" 2>/dev/null | jq -e '
      (map(select(.subrole=="AXStandardWindow" and .title!="Picture-in-Picture"))) as $w
    | ($w|map(select('"$browser_sel"'))|first) as $browser
    | ($w|map(select('"$editor_sel"'))|first)  as $ed
    | ($w|map(select(.app=="Ghostty"))|first)  as $gho
    | ([$browser,$ed,$gho]|map(select(.!=null))|length) as $n
    | if $n <= 1 then true
      elif $ed then
        ($browser and $gho)
        and ($ed.frame.x > $browser.frame.x)
        and (($browser.frame.x|floor) == ($gho.frame.x|floor))
        and ($browser.frame.y < $gho.frame.y)
      else
        ($browser and $gho)
        and ($browser.frame.x < $gho.frame.x)
        and (($browser.frame.y|floor) == ($gho.frame.y|floor))
      end
  ' >/dev/null 2>&1
}
```

- [ ] **Step 3: Syntax-check**

Run: `sh -n mac/yabai/yabairc && echo OK`
Expected: `OK`

- [ ] **Step 4: Read-only test — prove the NEW code reports CORRECT** for the golden layout. Run the new predicate against live space 3:

Run:
```sh
sel='(.app=="Zen" or .app=="Google Chrome" or .app=="Safari" or .app=="Arc")'
yabai -m query --windows --space 3 | jq -e '
    (map(select(.subrole=="AXStandardWindow" and .title!="Picture-in-Picture"))) as $w
  | ($w|map(select('"$sel"'))|first) as $browser
  | ($w|map(select(.app=="Zed" or .app=="Code"))|first) as $ed
  | ($w|map(select(.app=="Ghostty"))|first) as $gho
  | ([$browser,$ed,$gho]|map(select(.!=null))|length) as $n
  | if $n <= 1 then true
    elif $ed then ($browser and $gho) and ($ed.frame.x > $browser.frame.x)
      and (($browser.frame.x|floor)==($gho.frame.x|floor)) and ($browser.frame.y < $gho.frame.y)
    else ($browser and $gho) and ($browser.frame.x < $gho.frame.x)
      and (($browser.frame.y|floor)==($gho.frame.y|floor)) end
' >/dev/null && echo "reports CORRECT" || echo "reports WRONG"
```
Expected: `reports CORRECT` (Chrome now fills the browser role).

- [ ] **Step 5: Commit**

```bash
git add mac/yabai/yabairc
git commit -m "yabai: external_correct recognizes any browser in the top-left slot"
```

---

### Task 4: Generalize `place_editors()`

**Files:**
- Modify: `mac/yabai/yabairc` — `place_editors()` (~lines 149-186) and add a `move_browsers()` helper near `move_editors()` (~line 44)

**Interfaces:**
- Consumes: `browser_id`, `browser_sel`, `external_correct`, `warp_to`, `ensure_tiled`.
- Produces: `place_editors <trigger>` — positions the browser (not Zen) in the top-left slot.

- [ ] **Step 1: Add `move_browsers()`** after `move_editors()`:

```sh
move_browsers() {  # move every browser window to space $1 (leaves the sticky PiP popout alone)
  yabai -m query --windows 2>/dev/null \
    | jq -r ".[]|select($browser_sel and .title!=\"Picture-in-Picture\")|.id" \
    | xargs -I{} yabai -m window {} --space "$1" 2>/dev/null
}
```

- [ ] **Step 2: Update the laptop-only branch** in `place_editors()`. Replace:

```sh
    log place "place($trigger): laptop only -> Zen:3 editors:4 Ghostty:5"
    move Zen 3; move_editors 4; move Ghostty 5
```
with:
```sh
    log place "place($trigger): laptop only -> browsers:3 editors:4 Ghostty:5"
    move_browsers 3; move_editors 4; move Ghostty 5
```

- [ ] **Step 3: Update the external/stacked branch.** Replace the line:

```sh
  eds=$(editor_ids); ed=$(echo "$eds" | head -1); zen=$(win_id Zen); gho=$(win_id Ghostty)
```
with:
```sh
  eds=$(editor_ids); ed=$(echo "$eds" | head -1); browser=$(browser_id); gho=$(win_id Ghostty)
```

Then in the same function replace every remaining `$zen` with `$browser`:
- the space-move loop `for id in $eds $zen $gho` → `for id in $eds $browser $gho`
- `for id in $ed $zen $gho; do ensure_tiled` → `for id in $ed $browser $gho; do ensure_tiled`
- `[ -n "$zen" ] && warp_to "$zen" "$ed" west` → `[ -n "$browser" ] && warp_to "$browser" "$ed" west`
- `[ -n "$gho" ] && warp_to "$gho" "${zen:-$ed}" south` → `warp_to "$gho" "${browser:-$ed}" south`
- `[ -n "$zen" ] && [ -n "$gho" ] && warp_to "$gho" "$zen" east` → `[ -n "$browser" ] && [ -n "$gho" ] && warp_to "$gho" "$browser" east`

- [ ] **Step 4: Confirm no `zen`/`Zen`-hardcode remains in `place_editors`**

Run: `awk '/^place_editors\(\)/,/^}/' mac/yabai/yabairc | grep -n 'zen\|win_id Zen\|move Zen' || echo "clean"`
Expected: `clean`

- [ ] **Step 5: Syntax-check**

Run: `sh -n mac/yabai/yabairc && echo OK`
Expected: `OK`

- [ ] **Step 6: Commit**

```bash
git add mac/yabai/yabairc
git commit -m "yabai: place_editors positions the browser slot (not Zen specifically)"
```

---

### Task 5: Generalize `adopt()` — exclude only the slot browser

**Files:**
- Modify: `mac/yabai/yabairc` — `adopt()` (~lines 69-83)

**Interfaces:**
- Consumes: `browser_id`, `EDITOR_APPS`, `editor_space`, `warp_to`.
- Produces: `adopt <window-id>` — the slot browser (id == `browser_id`) and Ghostty/editors are never adopted; a second browser window IS adopted under the editor.

- [ ] **Step 1: Replace the trio-member guard.** The current guard is a space-delimited app-name test that breaks on multi-word names. Replace:

```sh
  case " $EDITOR_APPS Zen Ghostty " in *" $app "*) return 0 ;; esac
```
with:
```sh
  # Never adopt trio members: editors + Ghostty by app; the slot browser by id
  # (a SECOND browser window has a different id and DOES get adopted).
  case " $EDITOR_APPS Ghostty " in *" $app "*) return 0 ;; esac
  [ "$id" = "$(browser_id)" ] && return 0
```

- [ ] **Step 2: Syntax-check**

Run: `sh -n mac/yabai/yabairc && echo OK`
Expected: `OK`

- [ ] **Step 3: Read-only logic test** — the current slot browser (Chrome) must be recognized as excluded, i.e. its id equals `browser_id`:

Run:
```sh
sel='(.app=="Zen" or .app=="Google Chrome" or .app=="Safari" or .app=="Arc")'
bid=$(yabai -m query --windows | jq -r ".[]|select($sel and .subrole==\"AXStandardWindow\" and .title!=\"Picture-in-Picture\")|.id" | head -1)
chrome=$(yabai -m query --windows | jq -r '.[]|select(.app=="Google Chrome" and .subrole=="AXStandardWindow")|.id' | head -1)
[ "$bid" = "$chrome" ] && echo "slot browser excluded (bid=$bid)" || echo "MISMATCH bid=$bid chrome=$chrome"
```
Expected: `slot browser excluded ...`

- [ ] **Step 4: Commit**

```bash
git add mac/yabai/yabairc
git commit -m "yabai: adopt excludes the slot browser by id, keeps editors/Ghostty by app"
```

---

### Task 6: Browser placement signal

**Files:**
- Modify: `mac/yabai/yabairc` — the `window_created app="^Zen$"` signal (~line 287)

**Interfaces:**
- Consumes: `BROWSER_RE`.
- Produces: opening any browser fires `place` (rebuilds the trio) just like opening Zen did.

- [ ] **Step 1: Replace the signal registration.** Change:

```sh
yabai -m signal --add event=window_created app="^Zen$"        action="\$HOME/Code/dotfiles/mac/yabai/yabairc place"
```
to:
```sh
yabai -m signal --add event=window_created app="$BROWSER_RE"  action="\$HOME/Code/dotfiles/mac/yabai/yabairc place"
```

- [ ] **Step 2: Syntax-check**

Run: `sh -n mac/yabai/yabairc && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add mac/yabai/yabairc
git commit -m "yabai: fire editor placement on any browser window_created, not just Zen"
```

---

### Task 7: Live verification (single reload) + release

**Files:**
- None (verification + optional release).

**Interfaces:**
- Consumes: the whole updated config.
- Produces: proof the fix works end-to-end.

- [ ] **Step 1: Confirm the golden layout is still on screen** (no accidental mutation during Tasks 1-6):

Run:
```sh
yabai -m query --windows | jq -r '.[]|select(.space==3 and .subrole=="AXStandardWindow")|"\(.app): x=\(.frame.x|floor) y=\(.frame.y|floor)"' | sort
```
Expected: `Ghostty x=12 y=916`, `Code x=1605 y=37`, `Google Chrome x=12 y=37` (matches golden_layout.txt).

- [ ] **Step 2: Reload yabai** (this is the real test — with the fix, startup `place_editors` must see `external_correct` true and SKIP the rebuild, preserving the layout):

Run: `yabai --restart-service`

- [ ] **Step 3: Verify the log shows SKIP, not rebuild.** After the reload settles (observe the log, do not sleep-guess):

Run: `grep -E '\[(load|place)\]' /tmp/yabai.log | tail -5`
Expected: a `place(startup): trio correct on space 3 — skip rebuild` line — NOT a "rebuild stacked/side-by-side" line.

- [ ] **Step 4: Verify the layout survived the reload** (compare to golden):

Run:
```sh
yabai -m query --windows | jq -r '.[]|select(.space==3 and .subrole=="AXStandardWindow")|"\(.app): x=\(.frame.x|floor) y=\(.frame.y|floor)"' | sort
```
Expected: identical to Step 1 — Chrome still top-left, Ghostty bottom-left, Code right.

- [ ] **Step 5 (optional, on user request): tag a release**

```bash
./release <next-version>   # check latest with: git tag --sort=-v:refname | head -1
```

---

## Notes for the implementer

- All edits are in one symlinked file; between tasks the config on disk changes but the *running* yabai keeps the pre-edit behavior until Task 7's reload. That's intentional — it keeps the user's layout stable while we build, and defers the only live-mutating step to the end.
- The read-only tests in Tasks 2/3/5 exploit the current state (Chrome in the slot, no Zen) as a live fixture. If the user closes Chrome / opens Zen before you run them, re-derive expectations from `browser_id` rather than assuming Chrome.
- If Task 7 Step 3 shows a rebuild instead of skip, STOP — return to systematic-debugging; do not patch blindly.
