import sys

sys.dont_write_bytecode = True

import importlib.util
import time

spec = importlib.util.spec_from_file_location(
    "comment_check", "/Users/karlm/Code/dotfiles/claude/hooks/comment-check.py"
)
hook = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hook)

ALLOW, BLOCK = "allow", "block"

FIXTURES = [
    (ALLOW, "sh", "zshrc guard", """# Herd appends HERD_PHP_INI_SCAN_DIR here on every PHP version change, so this
# must stay a real file; as a symlink those writes landed in tracked source.
if [ ! -f ~/.zshrc ]; then
    touch ~/.zshrc
fi
"""),
    (ALLOW, "js", "why a magic number", """// Safari fires resize before the viewport settles; 50ms is the shortest delay
// that measured stable across the devices we test on.
window.addEventListener('resize', () => setTimeout(recalculate, 50));
"""),
    (ALLOW, "py", "upstream bug reference", """# boto3 raises ConnectionClosedError instead of retrying here: see boto/boto3#3781.
for attempt in range(3):
    try:
        return client.put_object(**kwargs)
    except ConnectionClosedError:
        continue
"""),
    (ALLOW, "php", "docblock tooling reads", """<?php
/** @var \\App\\Models\\User $user */
$user = auth()->user();
"""),
    (ALLOW, "sh", "non-obvious ordering constraint", """# Must read the identity BEFORE link() replaces ~/.gitconfig; link() rm -rf's its
# target, so afterwards --global would read nothing.
GIT_NAME="$(git config --global --get user.name)"
link "$DOTFILES_DIR/git/gitconfig" ~/.gitconfig
"""),

    (BLOCK, "py", "narrates the loop", """# loop over the items
for item in items:
    process(item)
"""),
    (BLOCK, "js", "restates the line", """// increment the counter
counter += 1;
"""),
    (BLOCK, "js", "todo", """// TODO: fix this properly later
return cached ?? fetchFresh();
"""),
    (BLOCK, "php", "signature-echoing docblock", """<?php
/**
 * @param int $id
 * @return void
 */
public function destroy(int $id): void
{
    User::findOrFail($id)->delete();
}
"""),
    (BLOCK, "sh", "section label", """# --- helpers ---
say() { echo "$1"; }
"""),
    (BLOCK, "js", "commented-out code", """// console.log(response);
return response.data;
"""),
    (BLOCK, "py", "restates the function", """# this function adds two numbers
def add(a, b):
    return a + b
"""),
]

key = hook.read_api_key()
if not key:
    print("skipped: no API key at %s" % hook.API_KEY_PATH)
    sys.exit(0)

results = []
total_latency = 0.0

for expected, language, label, code in FIXTURES:
    syntax = hook.SYNTAX_BY_EXTENSION["." + language]
    comments = [
        (number, text) for number, text in hook.find_comments(code, syntax)
        if not hook.is_directive(text, hook.strip_marker(text))
    ]
    if not comments:
        print("NO COMMENTS EXTRACTED: %s" % label)
        continue
    started = time.time()
    answers = hook.ask_jev(key, language, code, comments).get("answers", {})
    elapsed = time.time() - started
    total_latency += elapsed
    scores = [answers.get("c%d" % i, {}).get("noul") for i in range(len(comments))]
    worst = min(s for s in scores if s is not None)
    results.append((expected, label, worst, elapsed, len(comments)))
    print("%-6s %-30s worst=%.3f  n=%d  %.2fs" % (expected, label, worst, len(comments), elapsed))

print("\n--- separation ---")
allows = [r[2] for r in results if r[0] == ALLOW]
blocks = [r[2] for r in results if r[0] == BLOCK]
print("justified   min=%.3f  max=%.3f" % (min(allows), max(allows)))
print("unjustified min=%.3f  max=%.3f" % (min(blocks), max(blocks)))
print("gap: %.3f (justified floor) vs %.3f (unjustified ceiling)" % (min(allows), max(blocks)))

print("\n--- threshold sweep ---")
for t in [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]:
    fp = sum(1 for r in results if r[0] == ALLOW and r[2] < t)
    fn = sum(1 for r in results if r[0] == BLOCK and r[2] >= t)
    print("  %.1f  false blocks=%d  missed=%d%s" % (t, fp, fn, "   <-- clean" if fp == 0 and fn == 0 else ""))

print("\nmean latency %.2fs over %d requests" % (total_latency / len(results), len(results)))

threshold = hook.threshold()
false_blocks = [r[1] for r in results if r[0] == ALLOW and r[2] < threshold]
missed = [r[1] for r in results if r[0] == BLOCK and r[2] >= threshold]

print("\n--- verdict at the configured threshold of %.2f ---" % threshold)
for label in false_blocks:
    print("  FALSE BLOCK: %s" % label)
for label in missed:
    print("  MISSED: %s" % label)
if false_blocks or missed:
    print("%d wrong out of %d" % (len(false_blocks) + len(missed), len(results)))
    sys.exit(1)
print("all %d fixtures correct" % len(results))
