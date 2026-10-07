---
name: read-aloud
description: Use when the user asks Claude to read something aloud, read it to them, say it out loud or speak it, such as "read that to me", "read me the last answer" or "read the plan out loud". Speaks text in full through the GLaDOS voice with glados-say.
---

# read-aloud

`glados-say` speaks text in the GLaDOS voice through Piper. A Stop hook already reads the end of every reply, capped at about 1,500 characters; this skill is for reading something in full on request.

## What to Read

- "that", "it", "the last answer" with nothing else named: your previous reply, in full.
- A named section, plan, file or document: that text. Read files with the Read tool first, then speak their contents.
- Speak the text as written. Don't summarize or reword it unless asked to.

## How to Speak It

Pipe the text through a quoted heredoc so nothing in it gets expanded by the shell:

```bash
glados-say --priority <<'GLADOS'
<the text>
GLADOS
```

- `--priority` stops the Stop hook from cutting the reading off when your turn ends. Always pass it.
- Leave out `--max` so the whole text is read. `glados-say` drops code blocks, tables and URLs on its own, so pass the text as it is.
- It returns right away and plays in the background. Don't pass `--wait`.

Then reply with one short line, such as "Reading it now." Don't repeat the text in your reply.

## Stopping

"Stop", "shut up" or "quiet" means run `glados-say --stop`.

## Volume

"Louder", "quieter" or a specific level means run `glados-say --volume <0-1>`. The setting is saved for future readings; the current value is in `~/.local/state/glados/volume` (default 0.3). Volume changes don't affect a reading that's already playing.

## Pronunciation

If a word comes out wrong, add a spelling that sounds right to the `PRONUNCIATIONS` map in `~/dotfiles/linuxbin/.local/bin/glados-say`.
