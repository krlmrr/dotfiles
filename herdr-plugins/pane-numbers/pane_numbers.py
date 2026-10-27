import json
import os
import subprocess
import sys
import time
import uuid
from pathlib import Path

HERDR = os.environ.get("HERDR_BIN_PATH", "herdr")
SHOWN = Path(os.environ.get("HERDR_PLUGIN_STATE_DIR", ".")) / "shown.json"
SHOW_FOR_SECONDS = 3


def herdr(*args):
    result = subprocess.run([HERDR, *args], capture_output=True, text=True)
    if result.returncode != 0 or not result.stdout.strip():
        return None
    return json.loads(result.stdout).get("result")


def panes_in_reading_order():
    layout = herdr("pane", "layout")["layout"]
    panes = sorted(layout["panes"], key=lambda pane: (pane["rect"]["y"], pane["rect"]["x"]))
    return layout["workspace_id"], [pane["pane_id"] for pane in panes]


def labels_of(workspace_id, pane_ids):
    panes = herdr("pane", "list", "--workspace", workspace_id)["panes"]
    labels = {pane["pane_id"]: pane.get("label") for pane in panes}
    return {pane_id: labels.get(pane_id) for pane_id in pane_ids}


def rename(pane_id, label):
    if label:
        herdr("pane", "rename", pane_id, label)
    else:
        herdr("pane", "rename", pane_id, "--clear")


def hide_numbers(only_token=None):
    try:
        shown = json.loads(SHOWN.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return
    if only_token and shown["token"] != only_token:
        return
    SHOWN.unlink(missing_ok=True)
    for pane_id, label in shown["labels"].items():
        rename(pane_id, label)


def show():
    hide_numbers()
    workspace_id, pane_ids = panes_in_reading_order()
    labels = labels_of(workspace_id, pane_ids)
    token = uuid.uuid4().hex
    SHOWN.write_text(json.dumps({"token": token, "labels": labels}))
    for number, pane_id in enumerate(pane_ids, start=1):
        label = labels[pane_id]
        rename(pane_id, f"{number} · {label}" if label else str(number))
    time.sleep(SHOW_FOR_SECONDS)
    hide_numbers(only_token=token)


def jump(number):
    hide_numbers()
    _, pane_ids = panes_in_reading_order()
    if 1 <= number <= len(pane_ids):
        herdr("pane", "zoom", pane_ids[number - 1], "--off")


if sys.argv[1] == "show":
    show()
else:
    jump(int(sys.argv[2]))
