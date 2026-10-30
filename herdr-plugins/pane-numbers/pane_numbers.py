import json
import os
import subprocess
import sys
import time
import uuid
from pathlib import Path

HERDR = os.environ.get("HERDR_BIN_PATH", "herdr")
SHOWN = Path(os.environ.get("HERDR_PLUGIN_STATE_DIR", ".")) / "shown.json"
AUTONAMED = Path(os.environ.get("HERDR_PLUGIN_STATE_DIR", ".")) / "autonamed.json"
SHOW_FOR_SECONDS = 3
SHELLS = {"zsh", "bash", "sh", "fish", "dash", "nu", "login"}


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
    current = labels_of(shown["workspace_id"], list(shown["labels"]))
    for pane_id, label in shown["labels"].items():
        if current[pane_id] == shown["numbered"][pane_id]:
            rename(pane_id, label)


def show():
    hide_numbers()
    workspace_id, pane_ids = panes_in_reading_order()
    labels = labels_of(workspace_id, pane_ids)
    token = uuid.uuid4().hex
    numbered = {
        pane_id: f"{number} · {labels[pane_id]}" if labels[pane_id] else str(number)
        for number, pane_id in enumerate(pane_ids, start=1)
    }
    SHOWN.write_text(json.dumps({"token": token, "workspace_id": workspace_id, "labels": labels, "numbered": numbered}))
    for pane_id, label in numbered.items():
        rename(pane_id, label)
    time.sleep(SHOW_FOR_SECONDS)
    hide_numbers(only_token=token)


def jump(number):
    hide_numbers()
    _, pane_ids = panes_in_reading_order()
    if 1 <= number <= len(pane_ids):
        herdr("pane", "zoom", pane_ids[number - 1], "--off")


def pane_in_event():
    event = json.loads(os.environ.get("HERDR_PLUGIN_EVENT_JSON", "{}"))
    while isinstance(event, dict):
        if "pane_id" in event:
            return event["pane_id"]
        event = event.get("data") or event.get("pane") or event.get("payload")
    return None


def program_in(pane_id):
    info = herdr("pane", "process-info", "--pane", pane_id)
    if not info:
        return None
    info = info["process_info"]
    leaders = [p["name"] for p in info["foreground_processes"] if p["pid"] == info["foreground_process_group_id"]]
    name = (leaders or [None])[0]
    if not name or name.lstrip("-") in SHELLS:
        return None
    return name[0].upper() + name[1:]


def autoname():
    pane_id = pane_in_event()
    if not pane_id:
        return
    pane = herdr("pane", "get", pane_id)
    if not pane:
        return
    current = pane["pane"].get("label")
    try:
        autonamed = json.loads(AUTONAMED.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        autonamed = {}
    if current is not None and current != autonamed.get(pane_id):
        return
    name = program_in(pane_id)
    if name == current:
        return
    rename(pane_id, name)
    if name:
        autonamed[pane_id] = name
    else:
        autonamed.pop(pane_id, None)
    AUTONAMED.write_text(json.dumps(autonamed))


if sys.argv[1] == "show":
    show()
elif sys.argv[1] == "autoname":
    autoname()
else:
    jump(int(sys.argv[2]))
