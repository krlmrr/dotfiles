---
name: feedback-cleanup-remote-state
description: Clean up temp state I create on remote systems (debug containers, background processes, scratch files) at the end of the operation — don't trust auto-cleanup
metadata:
  type: feedback
---

When running ad-hoc debug commands on remote systems (the Synology, any SSH target, any docker host), the state I create is my responsibility to remove at the end of the task. Examples:

- `docker run --rm ... &` — the `--rm` only fires if the container EXITS cleanly. If I kill the local `docker` CLI (or the SSH session dies, or a pipe closes early), the container keeps running on the host forever. This happened on the Synology — left three orphan zensync-test containers running for hours.
- Scratch files in `/tmp` on remote hosts (decompressed profile dumps, log captures).
- Background processes started via SSH that survive after I disconnect.

**Why:** Karl found three orphaned containers running on his NAS hours after I'd "finished" debugging. He had to point them out. Leaving runtime state behind is the same class of problem as leaving build artifacts in git — it pollutes the user's environment and makes future operations confusing ("what are these?").

**How to apply:**
- After any debug operation that creates a container/process/file on a remote host, **list and verify** what got left behind before declaring done. `docker ps -a` after debug runs. `ls /tmp` after scratch work.
- Prefer foreground over background for short debug runs — if I need output, capture it inline rather than backgrounding and reading later.
- When backgrounding IS necessary, set a name (`--name foo-debug`) so cleanup is explicit (`docker rm -f foo-debug`).
- For any multi-step debug session, end with an explicit cleanup pass and report what was removed.
- Don't rely on `--rm` or `&& cleanup` as the only safety net — they fail under signal kills.

Related: [[feedback-stop-guessing]] — same family of "be deliberate, don't fire-and-forget."
