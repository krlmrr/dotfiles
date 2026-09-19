#!/usr/bin/env python3

import sys

sys.dont_write_bytecode = True

import importlib.util
import json
import os
import subprocess
import tempfile

HOOK_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "claude", "hooks", "comment-check.py",
)

spec = importlib.util.spec_from_file_location("comment_check", HOOK_PATH)
hook = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hook)

failures = []
passes = 0


def check(name, actual, expected):
    global passes
    if actual == expected:
        passes += 1
        return
    failures.append("%s\n    expected: %r\n    actual:   %r" % (name, expected, actual))


def comments_in(source, syntax):
    return [text for _, text in hook.find_comments(source, syntax)]


check(
    "shell line comment",
    comments_in("#!/bin/bash\n# set the flag\nFLAG=1\n", hook.HASH),
    ["#!/bin/bash", "# set the flag"],
)

check(
    "hash inside a double-quoted string is not a comment",
    comments_in('echo "the # character"\n', hook.HASH),
    [],
)

check(
    "slash comment after code",
    comments_in("const x = 1; // increment\n", hook.SLASH),
    ["// increment"],
)

check(
    "url inside a string is not a comment",
    comments_in('const url = "https://example.com/path";\n', hook.SLASH),
    [],
)

check(
    "single-line block comment",
    comments_in("/* a note */\ncode();\n", hook.SLASH),
    ["a note"],
)

check(
    "multi-line block comment collapses to one entry",
    comments_in("/**\n * @param int $id\n * @return void\n */\nfunction f() {}\n", hook.SLASH),
    ["@param int $id @return void"],
)

check(
    "markup comment",
    comments_in("<!-- nav starts -->\n<div></div>\n", hook.MARKUP),
    ["nav starts"],
)

check(
    "sql dash comment",
    comments_in("-- drop the index\nDROP INDEX i;\n", hook.DASH),
    ["-- drop the index"],
)


def directive(text):
    return hook.is_directive(text, hook.strip_marker(text))


check("shebang is a directive", directive("#!/usr/bin/env python3"), True)
check("shellcheck disable is a directive", directive("# shellcheck disable=SC2086"), True)
check("eslint-disable is a directive", directive("// eslint-disable-next-line"), True)
check("ts-expect-error is a directive", directive("// @ts-expect-error"), True)
check("noqa is a directive", directive("# noqa: E501"), True)
check("copyright header is a directive", directive("# Copyright 2026 Karl Murray"), True)
check("prose comment is not a directive", directive("# set the flag"), False)
check("todo is not a directive", directive("// TODO: fix this later"), False)
check("param docblock is not a directive", directive("* @param int $id"), False)


check(".md is skipped", hook.syntax_for("/tmp/notes.md"), None)
check(".json is skipped", hook.syntax_for("/tmp/data.json"), None)
check(".py resolves to hash", hook.syntax_for("/tmp/a.py"), hook.HASH)
check("Dockerfile resolves by filename", hook.syntax_for("/tmp/Dockerfile"), hook.HASH)
check("blade resolves to markup", hook.syntax_for("/tmp/page.blade.php"), hook.MARKUP)
check("unknown extension resolves to nothing", hook.syntax_for("/tmp/a.xyz"), None)


with tempfile.TemporaryDirectory() as directory:
    nested = os.path.join(directory, "src", "deep")
    os.makedirs(nested)
    target = os.path.join(nested, "a.py")
    open(target, "w").close()
    check("no opt-out file means enforced", hook.opted_out(target), False)
    open(os.path.join(directory, hook.OPT_OUT_FILENAME), "w").close()
    check("opt-out file at repo root is found from a nested file", hook.opted_out(target), True)


def fake_judge(scores):
    def judge(api_key, language, source, candidates):
        return {
            "answers": {
                "c%d" % index: {"type": "noul", "noul": scores[index]}
                for index in range(len(candidates))
            }
        }
    return judge


source_with_two = "#!/bin/bash\n# set the flag\nFLAG=1\n# guard against the upstream race\nsleep 1\n"

check(
    "unjustified comment is reported, shebang never reaches the model",
    hook.evaluate("a.sh", source_with_two, source_with_two, hook.HASH, "k", fake_judge([0.05, 0.9])),
    [(2, "# set the flag", 0.05)],
)

check(
    "justified comment passes",
    hook.evaluate("a.sh", source_with_two, source_with_two, hook.HASH, "k", fake_judge([0.9, 0.9])),
    [],
)

check(
    "pre-existing comments are ignored when not in the added text",
    hook.evaluate("a.sh", source_with_two, "FLAG=1\n", hook.HASH, "k", fake_judge([0.0, 0.0])),
    [],
)

check(
    "a file of only directives makes no call at all",
    hook.evaluate(
        "a.sh", "#!/bin/bash\n# shellcheck disable=SC2086\nls $x\n",
        "#!/bin/bash\n# shellcheck disable=SC2086\nls $x\n",
        hook.HASH, "k",
        lambda *args: (_ for _ in ()).throw(AssertionError("model was called")),
    ),
    [],
)


def run_hook(payload, environment=None):
    env = dict(os.environ)
    env.pop("TYPESAFE_API_KEY", None)
    env.update(environment or {})
    result = subprocess.run(
        [sys.executable, HOOK_PATH],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        env=env,
    )
    return result.returncode


check(
    "malformed stdin never blocks",
    subprocess.run([sys.executable, HOOK_PATH], input="not json", capture_output=True, text=True).returncode,
    0,
)

check(
    "missing file_path never blocks",
    run_hook({"tool_name": "Edit", "tool_input": {}}),
    0,
)

with tempfile.TemporaryDirectory() as directory:
    target = os.path.join(directory, "a.py")
    with open(target, "w") as handle:
        handle.write("# narrate the loop\nfor i in range(3):\n    pass\n")
    payload = {
        "tool_name": "Write",
        "tool_input": {"file_path": target, "content": "# narrate the loop\n"},
    }
    check(
        "no API key degrades to allowing the edit",
        run_hook(payload, {"HOME": directory}),
        0,
    )

import http.server
import threading


class StubHandler(http.server.BaseHTTPRequestHandler):
    scores = {}

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        request = json.loads(self.rfile.read(length))
        answers = {
            key: {"type": "noul", "noul": StubHandler.scores.get(key, 0.0)}
            for key in request.get("questions", {})
        }
        body = json.dumps({"answers": answers}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


server = http.server.HTTPServer(("127.0.0.1", 0), StubHandler)
threading.Thread(target=server.serve_forever, daemon=True).start()
stub_url = "http://127.0.0.1:%d/v1/systemone" % server.server_address[1]


def run_end_to_end(file_contents, added, scores, extra_env=None):
    StubHandler.scores = scores
    with tempfile.TemporaryDirectory() as directory:
        target = os.path.join(directory, "a.py")
        with open(target, "w") as handle:
            handle.write(file_contents)
        env = dict(os.environ)
        env.update({
            "TYPESAFE_API_KEY": "test-key",
            "COMMENT_CHECK_API_URL": stub_url,
        })
        env.update(extra_env or {})
        if extra_env and extra_env.get("OPT_OUT"):
            open(os.path.join(directory, hook.OPT_OUT_FILENAME), "w").close()
        result = subprocess.run(
            [sys.executable, HOOK_PATH],
            input=json.dumps({
                "tool_name": "Write",
                "tool_input": {"file_path": target, "content": added},
            }),
            capture_output=True,
            text=True,
            env=env,
        )
        return result.returncode, result.stderr


narrating = "# loop over the items\nfor item in items:\n    pass\n"

code, stderr = run_end_to_end(narrating, narrating, {"c0": 0.02})
check("end to end: unjustified comment exits 2", code, 2)
check("end to end: message names the comment", "# loop over the items" in stderr, True)
check("end to end: message names the rule", "general" in stderr, True)

code, stderr = run_end_to_end(narrating, narrating, {"c0": 0.97})
check("end to end: justified comment exits 0", code, 0)

code, stderr = run_end_to_end(narrating, narrating, {"c0": 0.02}, {"COMMENT_CHECK_THRESHOLD": "0.01"})
check("end to end: threshold is tunable", code, 0)

code, stderr = run_end_to_end(narrating, narrating, {"c0": 0.02}, {"OPT_OUT": "1"})
check("end to end: opt-out file disables the check", code, 0)

code, stderr = run_end_to_end(
    narrating, narrating, {"c0": 0.02},
    {"COMMENT_CHECK_API_URL": "http://127.0.0.1:1/v1/systemone"},
)
check("end to end: unreachable API never blocks the edit", code, 0)

server.shutdown()


CONFIGURE_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "configure"
)


def extract_merge_snippet():
    lines = open(CONFIGURE_PATH).read().splitlines()
    start = next(
        index for index, line in enumerate(lines)
        if line.startswith("python3 - \"$HOME/.claude/settings.json\"")
    )
    end = next(
        index for index, line in enumerate(lines[start:], start=start)
        if line == "PYHOOK"
    )
    return "\n".join(lines[start + 1:end])


existing_settings = {
    "hooks": {
        "SessionStart": [{
            "matcher": "*",
            "hooks": [{"type": "command", "command": "bash 'herdr.sh' session", "timeout": 10}],
        }],
    },
    "permissions": {"allow": ["Bash(ls:*)"]},
}

with tempfile.TemporaryDirectory() as directory:
    snippet = os.path.join(directory, "merge.py")
    with open(snippet, "w") as handle:
        handle.write(extract_merge_snippet())
    settings_path = os.path.join(directory, "settings.json")
    with open(settings_path, "w") as handle:
        json.dump(existing_settings, handle)

    for _ in range(3):
        subprocess.run([sys.executable, snippet, settings_path], check=True)

    merged = json.load(open(settings_path))
    post = merged["hooks"]["PostToolUse"]
    check("settings merge: registers exactly one entry after three runs", len(post), 1)
    check("settings merge: matches the edit tools", post[0]["matcher"], "Edit|Write|MultiEdit")
    check(
        "settings merge: leaves SessionStart untouched",
        merged["hooks"]["SessionStart"], existing_settings["hooks"]["SessionStart"],
    )
    check(
        "settings merge: leaves unrelated keys untouched",
        merged["permissions"], existing_settings["permissions"],
    )

with tempfile.TemporaryDirectory() as directory:
    snippet = os.path.join(directory, "merge.py")
    with open(snippet, "w") as handle:
        handle.write(extract_merge_snippet())
    settings_path = os.path.join(directory, "settings.json")
    subprocess.run([sys.executable, snippet, settings_path], check=True)
    check(
        "settings merge: creates the file when absent",
        len(json.load(open(settings_path))["hooks"]["PostToolUse"]), 1,
    )


print("%d passed, %d failed" % (passes, len(failures)))
for failure in failures:
    print("\nFAIL: %s" % failure)
sys.exit(1 if failures else 0)
