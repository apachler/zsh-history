# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository overview

A Zsh plugin derived from Oh-My-Zsh's [`lib/history.zsh`](https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/history.zsh) that wraps the built-in `history` command. The wrapper adds:

- `-c` — truncate `$HISTFILE`
- `-l` — passthrough to `fc`
- `-s PATTERN` — grep history for an extended-regex
- `-d N` — remove event N from `$HISTFILE`
- `--top N` — rank most-used commands by first word

…and configures `HISTFILE` / `HISTSIZE` / `SAVEHIST` defaults plus the history-related `setopt`s. Two optional surfaces sit alongside the wrapper: a `zshaddhistory` filter driven by `ZSH_HISTORY_IGNORE`, and an opt-in fzf `^R` widget gated on `HIST_FZF=1`.

Layout:

```
zsh-history.plugin.zsh        # the plugin (entry point)
completions/_history          # #compdef stub for the new flags
tests/
  run.zsh                     # discovers and runs test_*.zsh in subshells
  helpers.zsh                 # assertion primitives + `quiet` helper
  coverage.zsh                # xtrace-based line coverage; gates on COVERAGE_MIN%
  test_command_branches.zsh   # every flag of `zsh_history`
  test_hist_stamps.zsh        # HIST_STAMPS dispatch + quoting
  test_defaults.zsh           # HISTFILE/HISTSIZE/SAVEHIST defaults, unalias guard
  test_filter.zsh             # ZSH_HISTORY_IGNORE / _zsh_history_filter
  test_fzf_gate.zsh           # the three-way HIST_FZF gate
.github/
  dependabot.yml              # weekly Actions-version bump PRs
  workflows/
    smoke.yml                 # zsh -n + behavior assertions (Linux + macOS)
    test.yml                  # tests + coverage gate (Linux + macOS)
    links.yml                 # weekly lychee link-check on Markdown
    release.yml               # cuts a GitHub release on `v*` tag push
```

No external test framework. The runner is plain zsh; assertions live in
`tests/helpers.zsh`. Coverage is computed by re-running every test under
`setopt xtrace` via a temp `ZDOTDIR/.zshenv`, then counting unique plugin
lines in the trace divided by an `awk`-detected executable-line set
(skips multi-line single-quoted string bodies, function-definition
lines, and regions marked `# nocov-start` … `# nocov-end`).
`shellcheck` has no zsh mode, so `zsh -n` plus the test suite is the
only static gate.

## Architecture notes

- **Plugin loader convention.** Lines 4–5 of `zsh-history.plugin.zsh` follow the [Zsh Plugin Standard](https://github.com/zdharma/Zsh-100-Commits-Club/blob/master/Zsh-Plugin-Standard.adoc) for resolving `$0` so the plugin works under `zplug`, `zinit`, Oh-My-Zsh, manual sourcing, etc. Preserve this block when editing — it's the entry-point contract with plugin managers.
- **`zparseopts -E -D`.** `-E` keeps unknown flags (e.g. the `HIST_STAMPS`-derived `-f`/`-E`/`-i`/`-t`) in `$@` so they pass through to `fc`; `-D` strips the flags we recognize. When adding new flags, follow the existing pattern (`s+:=…`, `d+:=…`, `-top:=…`). The `-l` branch deliberately re-prepends `-l` because `-D` removed it.
- **Timestamp aliasing via `HIST_STAMPS`.** The `case ${HIST_STAMPS-}` block maps the user's `HIST_STAMPS` env var to an `fc` flag and aliases `history` to `zsh_history` with that flag. Adding a new format means adding a branch here, not modifying `zsh_history`. Use `${(q)HIST_STAMPS}` for the wildcard branch — values may contain spaces or quotes.
- **`unalias history` guard** before the `alias` block makes re-sourcing safe and avoids losing to another plugin that defined `history` first.
- **Defaults are conditional.** `HISTFILE`, `HISTSIZE`, and `SAVEHIST` only get set when unset / below the floor. The integer compares use `${HISTSIZE:-0}` form so they don't error when the var is unset.
- **`setopt`s are unconditional.** The history-behavior `setopt`s near the bottom are set every time the plugin loads. This is intentional — they define the plugin's purpose. Adding new ones is fine; they belong here, not inside `zsh_history`.
- **`zshaddhistory` hook.** `_zsh_history_filter` is registered via `add-zsh-hook`. Returning `1` drops the line from both in-memory and disk. The hook only fires for interactively-entered commands — `print -s` and direct file writes bypass it, which is why CI tests the function directly rather than via `print -s`.
- **fzf surface is fully gated.** `HIST_FZF != 0` *and* `fzf` on `$PATH` *and* `[[ -o interactive ]]` — all three required. The plugin must remain a no-op for non-interactive shells.
- **`history -d` honesty.** Zsh has no API to remove an entry from the running shell's in-memory `$history` list. The wrapper rewrites `HISTFILE` and the running shell catches up next time it loads. The user-facing message reflects this.

## Conventions

- Target Zsh only (shebang is `#!/usr/bin/env zsh`); no Bash-only constructs. Prefer `[[ … ]]` over `[ … ]`, and `print -ru2 --` over `echo` for messages.
- Use `builtin fc` rather than bare `fc` inside `zsh_history` to avoid recursing through the alias.
- Two-space indentation, lowercase function names.
- Quote `$HISTFILE` everywhere — paths can contain spaces (especially the `XDG_STATE_HOME` branch).
- Don't shell out to `tac` or other GNU-only tools — macOS doesn't ship them. The `awk` approach in `history -d` is the pattern to follow when ordering matters.

## Testing changes

Run the assertion suite and the coverage gate:

```zsh
zsh tests/run.zsh                       # 52 cases, exits nonzero on any failure
zsh tests/coverage.zsh                  # fails if coverage < ${COVERAGE_MIN:-80}%
VERBOSE=1 zsh tests/coverage.zsh        # also prints which lines were missed
```

The plugin can also be exercised by hand in a fresh shell:

```zsh
zsh -n zsh-history.plugin.zsh                # syntax
source ./zsh-history.plugin.zsh              # smoke load

history                                      # list all
history 10                                   # from event 10
history -10                                  # last 10
history -l 1                                 # fc passthrough
history -s 'git (push|pull)'                 # search
history -d 42                                # delete event 42 from HISTFILE
history --top 5                              # most-used commands

HIST_STAMPS="yyyy-mm-dd" zsh -c 'source ./zsh-history.plugin.zsh; alias history'
HIST_STAMPS="weird'quote" zsh -c 'source ./zsh-history.plugin.zsh; alias history'

ZSH_HISTORY_IGNORE='(*--token=*|*PASSWORD=*)' zsh -c '
  source ./zsh-history.plugin.zsh
  _zsh_history_filter "curl --token=ABC" && echo BUG || echo "rejected: ok"
'
```

For the fzf widget you need an interactive zsh:

```zsh
HIST_FZF=1 zsh -i
# then press ^R
```
