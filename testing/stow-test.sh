#!/bin/bash
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED="$DOTFILES/testing/expected-links.txt"
FAKE_HOME="$(mktemp -d)"
trap 'rm -rf "$FAKE_HOME"' EXIT

fail=0
pass=0

resolve() {
    python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

assert_link() {
    local rel_home="$1" rel_repo="$2"
    local target="$FAKE_HOME/$rel_home"
    local want

    want="$(resolve "$DOTFILES/$rel_repo")" || {
        echo "FAIL  resolve errored $rel_home"
        fail=$((fail + 1))
        return
    }
    [ -n "$want" ] || {
        echo "FAIL  resolve empty   $rel_home"
        fail=$((fail + 1))
        return
    }

    if [ ! -L "$target" ] && [ ! -e "$target" ]; then
        echo "FAIL  missing        $rel_home"
        fail=$((fail + 1))
        return
    fi

    local got
    got="$(resolve "$target")" || {
        echo "FAIL  resolve errored $rel_home"
        fail=$((fail + 1))
        return
    }
    [ -n "$got" ] || {
        echo "FAIL  resolve empty   $rel_home"
        fail=$((fail + 1))
        return
    }

    if [ "$got" != "$want" ]; then
        echo "FAIL  wrong target   $rel_home"
        echo "        want: $want"
        echo "        got:  $got"
        fail=$((fail + 1))
        return
    fi

    pass=$((pass + 1))
}

if [ $# -eq 0 ]; then
    echo "usage: stow-test.sh <package>..." >&2
    exit 2
fi

for pkg in "$@"; do
    if [ ! -d "$DOTFILES/$pkg" ]; then
        echo "FAIL  no such package $pkg"
        fail=$((fail + 1))
        continue
    fi
    stow --dir="$DOTFILES" --target="$FAKE_HOME" "$pkg" || {
        echo "FAIL  stow errored    $pkg"
        fail=$((fail + 1))
    }
done

while read -r pkg rel_home rel_repo; do
    case "$pkg" in ''|'#'*) continue ;; esac
    for want_pkg in "$@"; do
        [ "$pkg" = "$want_pkg" ] && assert_link "$rel_home" "$rel_repo"
    done
done < "$EXPECTED"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
