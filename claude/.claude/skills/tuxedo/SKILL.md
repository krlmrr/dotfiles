---
name: tuxedo
description: Use when adding, editing, completing, prioritizing or deleting tasks or todos, or when the user mentions tux, tuxedo or a todo.txt file.
---

# tuxedo

`tux` is an alias for `tuxedo`, a todo.txt TUI whose CLI edits the file from the shell. Lists are per project: each repo keeps its own `todo.txt`, and `done.txt` sits beside it. Aliases don't exist in agent shells, so always call `tuxedo`.

## Pick the File First

Prefix **every** command with `TODO_FILE=<absolute path to todo.txt>`:

```bash
TODO_FILE=~/Code/tql/todo.txt tuxedo add "Fix the TUI background +tql @dev due friday" --json
```

Without `TODO_FILE` (and with no `todo.txt` in the cwd), tuxedo writes to a throwaway sample in the temp dir that resets on the next run. It still reports `"ok":true`, so the task is silently lost. If the project has no `todo.txt` yet, ask before creating one (`TODO_FILE` creates it).

Reading needs no CLI: read the file directly or use `tuxedo ls --json`.

## Commands

N is the file line number, as reported in the `n` field.

| Need | Command |
|---|---|
| Add | `tuxedo add "(A) Text +project @context due friday" --json` |
| Find N | `tuxedo ls [+project\|@context\|text] --json` |
| Complete | `tuxedo do N --json` |
| Priority / remove it | `tuxedo pri N A --json` / `tuxedo depri N --json` |
| Add text to end / start | `tuxedo append N "text" --json` / `tuxedo prepend N "text" --json` |
| Rewrite | `tuxedo replace N "full new text" --json` |
| Delete | `tuxedo del N -f --json` |

Success prints JSON with `"ok":true` and the resulting `raw` line. Failure exits 1 with a plain-text message (`tuxedo: no task 99`), so check the exit code.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Reusing N from an earlier command | Numbers shift: `do` on a `rec:` task inserts the next occurrence below it, and `del` removes a line. Run `ls --json` and match on text right before each change. |
| `due:friday` | Stays the literal word. Write `due friday` (space) or `due:2026-10-02`. |
| `del N` without `-f` | Waits for a y/n prompt, deletes nothing, still returns `"ok":true`. |
| `replace` for a small edit | Drops the creation date and priority unless you retype them. Prefer `append`/`prepend`/`pri`. |
