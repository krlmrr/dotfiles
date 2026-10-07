#!/usr/bin/env python3

import json
import os
import subprocess
import sys

MUTE_FILE = os.path.expanduser("~/.local/state/glados/muted")
GLADOS_SAY = os.path.expanduser("~/.local/bin/glados-say")
MAX_CHARS = "1500"


def last_message_from_transcript(path):
    text = ""
    try:
        with open(path) as transcript:
            for line in transcript:
                try:
                    entry = json.loads(line)
                except ValueError:
                    continue
                message = entry.get("message") or {}
                if entry.get("type") != "assistant" or message.get("role") != "assistant":
                    continue
                parts = [
                    block.get("text", "")
                    for block in message.get("content", [])
                    if isinstance(block, dict) and block.get("type") == "text"
                ]
                if any(parts):
                    text = "\n".join(parts)
    except OSError:
        pass
    return text


def main():
    if os.path.exists(MUTE_FILE) or not os.path.exists(GLADOS_SAY):
        return
    payload = json.load(sys.stdin)
    if payload.get("stop_hook_active"):
        return
    message = payload.get("last_assistant_message") or last_message_from_transcript(
        payload.get("transcript_path", "")
    )
    if message.strip():
        subprocess.run([GLADOS_SAY, "--yield", "--max", MAX_CHARS], input=message.encode())


if __name__ == "__main__":
    main()
