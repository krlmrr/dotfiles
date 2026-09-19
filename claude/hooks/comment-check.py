#!/usr/bin/env python3

import json
import os
import re
import sys
import urllib.error
import urllib.request

API_URL = os.environ.get(
    "COMMENT_CHECK_API_URL", "https://api.typesafe.ai/v1/systemone"
)
API_KEY_PATH = os.path.expanduser("~/.config/typesafe/api-key")
OPT_OUT_FILENAME = ".no-comment-check"
DEFAULT_THRESHOLD = 0.5
REQUEST_TIMEOUT = 5.0
MAX_COMMENTS = 20

HASH = ("#", None, None)
SLASH = ("//", "/*", "*/")
DASH = ("--", None, None)
MARKUP = (None, "<!--", "-->")

SYNTAX_BY_EXTENSION = {
    ".sh": HASH, ".bash": HASH, ".zsh": HASH, ".py": HASH, ".rb": HASH,
    ".pl": HASH, ".yaml": HASH, ".yml": HASH, ".toml": HASH, ".r": HASH,
    ".js": SLASH, ".mjs": SLASH, ".cjs": SLASH, ".ts": SLASH, ".jsx": SLASH,
    ".tsx": SLASH, ".php": SLASH, ".c": SLASH, ".h": SLASH, ".cpp": SLASH,
    ".hpp": SLASH, ".java": SLASH, ".go": SLASH, ".rs": SLASH, ".swift": SLASH,
    ".kt": SLASH, ".scala": SLASH, ".m": SLASH, ".mm": SLASH, ".css": SLASH,
    ".scss": SLASH, ".less": SLASH,
    ".sql": DASH, ".lua": DASH, ".hs": DASH,
    ".html": MARKUP, ".xml": MARKUP, ".vue": MARKUP, ".svelte": MARKUP,
}

SYNTAX_BY_FILENAME = {
    "Dockerfile": HASH, "Makefile": HASH, "Gemfile": HASH, "Rakefile": HASH,
    "Brewfile": HASH, "Procfile": HASH,
}

DIRECTIVE_PATTERNS = [
    r"^#!",
    r"^shellcheck\b", r"^shellcheck\s+disable",
    r"^eslint[-\s]", r"^prettier-ignore", r"^stylelint-",
    r"^@ts-(ignore|expect-error|nocheck)",
    r"^type:\s*ignore", r"^noqa\b", r"^pragma\b", r"^pylint:", r"^mypy:",
    r"^rubocop:", r"^nolint\b", r"^golint\b", r"^go:generate",
    r"^phpcs:", r"^phpstan-", r"^psalm-", r"^@codeCoverageIgnore",
    r"^\s*<\?xml", r"^!\s*$",
    r"^-\*-", r"^coding[:=]", r"^vim:", r"^Copyright\b", r"^SPDX-License",
]

SKIP_EXTENSIONS = {".md", ".mdx", ".txt", ".json", ".lock", ".snap"}

QUESTION_CRITERIA = {
    "true": (
        "The comment carries information the code itself cannot: an explanation "
        "of WHY a non-obvious choice was made, a warning about a real constraint "
        "or gotcha, a reference to an external cause (a bug report, a spec, an "
        "upstream quirk), a license or copyright header, or an annotation that "
        "a framework, compiler, IDE or static analyser actually parses and acts "
        "on - a @var type hint, @template, @phpstan-*, @psalm-*, @deprecated, or "
        "a @see pointer - since those carry type or tooling information the "
        "surrounding code does not state."
    ),
    "false": (
        "The comment restates in English what the code already says, narrates the "
        "next line or block, labels a section, is a TODO or FIXME, is commented-out "
        "code, or is a docblock that only repeats the function signature and "
        "parameter names without adding meaning."
    ),
}


def log_debug(message):
    if os.environ.get("COMMENT_CHECK_DEBUG"):
        sys.stderr.write("comment-check: %s\n" % message)


def syntax_for(path):
    basename = os.path.basename(path)
    _, extension = os.path.splitext(basename)
    extension = extension.lower()
    if extension in SKIP_EXTENSIONS:
        return None
    if basename in SYNTAX_BY_FILENAME:
        return SYNTAX_BY_FILENAME[basename]
    if basename.endswith(".blade.php"):
        return MARKUP
    return SYNTAX_BY_EXTENSION.get(extension)


def clean_block_part(text):
    return text.strip().lstrip("*").strip()


def strip_marker(text):
    return text.lstrip("#/*-<! \t").rstrip("*/->\t ").strip()


def is_directive(raw, stripped):
    if raw.startswith("#!"):
        return True
    for pattern in DIRECTIVE_PATTERNS:
        if re.search(pattern, stripped, re.IGNORECASE):
            return True
    return False


def find_comments(source, syntax):
    line_marker, block_open, block_close = syntax
    comments = []
    in_block = False
    block_start_line = 0
    block_parts = []

    for line_number, line in enumerate(source.splitlines(), start=1):
        if in_block:
            end = line.find(block_close)
            if end == -1:
                block_parts.append(clean_block_part(line))
                continue
            block_parts.append(clean_block_part(line[:end]))
            comments.append((block_start_line, " ".join(block_parts).strip()))
            in_block = False
            block_parts = []
            line = line[end + len(block_close):]

        index = 0
        in_string = None
        while index < len(line):
            character = line[index]
            if in_string:
                if character == "\\":
                    index += 2
                    continue
                if character == in_string:
                    in_string = None
                index += 1
                continue
            if character in "\"'`":
                in_string = character
                index += 1
                continue
            if block_open and line.startswith(block_open, index):
                end = line.find(block_close, index + len(block_open))
                if end == -1:
                    in_block = True
                    block_start_line = line_number
                    block_parts = [clean_block_part(line[index + len(block_open):])]
                    break
                comments.append(
                    (line_number, clean_block_part(line[index + len(block_open):end]))
                )
                index = end + len(block_close)
                continue
            if line_marker and line.startswith(line_marker, index):
                comments.append((line_number, line[index:].strip()))
                break
            index += 1

    return [(number, text) for number, text in comments if text]


def opted_out(path):
    directory = os.path.dirname(os.path.abspath(path))
    while True:
        if os.path.exists(os.path.join(directory, OPT_OUT_FILENAME)):
            return True
        parent = os.path.dirname(directory)
        if parent == directory:
            return False
        directory = parent


def read_api_key():
    key = os.environ.get("TYPESAFE_API_KEY", "").strip()
    if key:
        return key
    try:
        with open(API_KEY_PATH) as handle:
            return handle.read().strip()
    except OSError:
        return ""


def added_text(payload):
    tool_input = payload.get("tool_input") or {}
    if "content" in tool_input:
        return tool_input["content"] or ""
    if "new_string" in tool_input:
        return tool_input["new_string"] or ""
    edits = tool_input.get("edits") or []
    return "\n".join(edit.get("new_string", "") for edit in edits)


def build_questions(candidates):
    questions = {}
    for index, (line_number, text) in enumerate(candidates):
        questions["c%d" % index] = {
            "type": "noul",
            "instructions": (
                "The code in the state contains this comment on line %d: %r. "
                "Does that comment carry information that a competent reader "
                "cannot obtain from the code itself?" % (line_number, text)
            ),
            "criteria": QUESTION_CRITERIA,
        }
    return questions


def ask_jev(api_key, language, source, candidates):
    body = json.dumps({
        "state": {"language": language, "code": source},
        "model": "jev-latest",
        "questions": build_questions(candidates),
    }).encode("utf-8")

    request = urllib.request.Request(
        API_URL,
        data=body,
        headers={
            "Authorization": "Bearer %s" % api_key,
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT) as response:
        return json.loads(response.read().decode("utf-8"))


def threshold():
    try:
        return float(os.environ.get("COMMENT_CHECK_THRESHOLD", DEFAULT_THRESHOLD))
    except ValueError:
        return DEFAULT_THRESHOLD


def evaluate(path, source, added, syntax, api_key, judge=ask_jev):
    added_comments = {text for _, text in find_comments(added, syntax)}
    if not added_comments:
        return []

    candidates = []
    for line_number, text in find_comments(source, syntax):
        if text not in added_comments:
            continue
        if is_directive(text, strip_marker(text)):
            continue
        candidates.append((line_number, text))

    if not candidates:
        return []

    answers = judge(
        api_key,
        os.path.splitext(path)[1].lstrip(".") or "text",
        source,
        candidates[:MAX_COMMENTS],
    ).get("answers", {})

    limit = threshold()
    violations = []
    for index, (line_number, text) in enumerate(candidates[:MAX_COMMENTS]):
        answer = answers.get("c%d" % index) or {}
        probability = answer.get("noul")
        if probability is None:
            continue
        if probability < limit:
            violations.append((line_number, text, probability))
    return violations


def main():
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError) as error:
        log_debug("unreadable payload: %s" % error)
        return 0

    tool_input = payload.get("tool_input") or {}
    path = tool_input.get("file_path") or ""
    if not path:
        return 0

    syntax = syntax_for(path)
    if syntax is None:
        return 0

    if opted_out(path):
        log_debug("opted out via %s" % OPT_OUT_FILENAME)
        return 0

    added = added_text(payload)
    if not added.strip():
        return 0

    api_key = read_api_key()
    if not api_key:
        log_debug("no API key at %s" % API_KEY_PATH)
        return 0

    try:
        with open(path) as handle:
            source = handle.read()
    except OSError as error:
        log_debug("unreadable file: %s" % error)
        return 0

    try:
        violations = evaluate(path, source, added, syntax, api_key)
    except (urllib.error.URLError, OSError, ValueError, KeyError) as error:
        log_debug("judgement unavailable: %s" % error)
        return 0

    if not violations:
        return 0

    lines = [
        "Comments are not allowed in code (see the 'general' skill: no docblocks, "
        "no inline comments, no TODOs). Remove these from %s and express the same "
        "thing through naming and structure:" % path
    ]
    for line_number, text, probability in violations:
        lines.append("  %s:%d  %s" % (path, line_number, text))
    sys.stderr.write("\n".join(lines) + "\n")
    return 2


if __name__ == "__main__":
    sys.exit(main())
