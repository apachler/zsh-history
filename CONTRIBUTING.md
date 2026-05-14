# Contributing

Thanks for taking the time to contribute. This plugin is intentionally small — the bar is correctness, portability, and zero-cost-when-unused, not feature volume.

## Quick start

```zsh
git clone https://github.com/apachler/zsh-history
cd zsh-history

zsh -n zsh-history.plugin.zsh   # syntax check
zsh tests/run.zsh               # run the test suite (52 cases)
zsh tests/coverage.zsh          # coverage gate (>= COVERAGE_MIN, default 80%)
VERBOSE=1 zsh tests/coverage.zsh # also list missed lines
```

You need `zsh` 5.8+ and `awk` (BSD or GNU). `fzf` is only needed if you touch the fzf widget.

## What's in scope

- Bug fixes in the plugin or its tests.
- New flags on `zsh_history` that don't change existing flag semantics.
- Portability fixes (macOS BSD-awk, older zsh versions, alternative plugin managers).
- Docs improvements.

What we'd push back on:

- Adding heavyweight dependencies (Node, Python, Rust toolchains).
- Changing the `#!/usr/bin/env zsh` target — this is a zsh-only plugin.
- Bash-only constructs. Prefer `[[ … ]]`, `print -ru2 --`, `builtin fc`.

## Conventions

- Two-space indentation, lowercase function names.
- Quote `$HISTFILE` everywhere.
- New flags follow the `zparseopts -E -D` pattern already in place.
- Don't shell out to GNU-only tools (`tac`, GNU-specific `sed -i` flags). macOS doesn't ship them.
- See [`CLAUDE.md`](CLAUDE.md) for architectural notes.

## Tests

Every new branch needs a test. The runner is plain zsh — see `tests/helpers.zsh` for the assertion primitives. Coverage must stay at or above the threshold; mark genuinely-untestable regions with `# nocov-start` / `# nocov-end` and explain why in a comment.

## Commits and PRs

- Keep commits focused and self-explanatory; release notes are generated from commit subjects, so write subjects you'd be happy to see in a changelog.
- Reference the issue in the PR description, not the commit message.
- Sign commits if you can (GPG or SSH).
- One topic per PR; split unrelated changes.

## Code of conduct

Participation is governed by the [Contributor Covenant](CODE_OF_CONDUCT.md).

## Security

Don't open a public issue for security reports — see [`SECURITY.md`](SECURITY.md).
