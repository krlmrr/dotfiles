---
name: ghgrab
description: Use when reading source, docs or config from a GitHub or GitLab repository that isn't checked out locally, such as checking where a CLI tool reads its config, reading a few files or one folder, or grabbing a subtree, instead of cloning or downloading a release tarball.
---

# ghgrab

`ghgrab agent` lists and downloads parts of a remote repo as JSON, without cloning. Binary: `~/.cargo/bin/ghgrab` (use the full path; non-interactive shells may lack `~/.cargo/bin` on PATH).

## Quick Reference

| Need | Command |
|---|---|
| List every file (recursive) | `ghgrab agent tree <url> --token gh` |
| List at a tag/branch/subfolder | `ghgrab agent tree https://github.com/o/r/tree/v1.2.0/src --token gh` |
| Download a folder | `ghgrab agent download <url> src/ui --out <dir> --json --token gh` |
| Download specific files | `ghgrab agent download <url> a.rs b.rs --out <dir> --json --token gh` |
| Download a subtree | `ghgrab agent download <url> --subtree src/screens --out <dir> --json --token gh` |

- Always pass `--token gh`. It borrows the `gh` login for this run only; never save a token with `ghgrab config`.
- Always pass `--out` pointing at the session scratchpad. Files land in `<out>/<repo>/`.
- Pin a ref with a `/tree/<ref>` URL when matching an installed version (e.g. the tag Homebrew or cargo installed).

## Workflow

1. `agent tree` first, then filter `data.entries` (`path`, `kind`, `size`) to find what matters.
2. `agent download` only those paths, then read them locally.

## Reading Results

Output is `{api_version, ok, command, data, error}`. **The exit code is 0 even on failure**, so check `ok`; on `false`, report `error.code` and `error.message`. Download results list `data.downloaded_paths` and `data.errors`.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Trusting the exit code | Check `ok` in the JSON |
| Downloading several files that share a name (`mod.rs`, `index.ts`, `SKILL.md`) | Individual file paths are flattened into `<out>/<repo>/`, so same-named files overwrite each other while `downloaded_paths` still lists all of them. Download each file's parent folder (as a path or with `--subtree`) instead. A folder keeps its structure but lands under its last segment only (`src/screens/browse` → `<out>/<repo>/browse/`), so folders sharing a last name (`src/ui`, `tests/ui`) also collide; give each its own `--out`. |
| Reading `main` when the installed version is older | Use a `/tree/<tag>` URL |
| Cloning or fetching a tarball to read two files | `tree` + `download` of just those paths |
