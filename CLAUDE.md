# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository overview

A single-file Zsh plugin (`zsh-history.plugin.zsh`) derived from Oh-My-Zsh's [`lib/history.zsh`](https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/history.zsh). It replaces the built-in `history` command with a wrapper that adds `-c` (clear history file) and `-l` (passthrough to `fc`) modes, configures `HISTFILE` / `HISTSIZE` / `SAVEHIST` defaults, and sets the history-related `setopt`s.

There is no build system, test suite, or linter — changes are made directly to the plugin file and validated by loading it in a Zsh shell.

## Architecture notes

- **Plugin loader convention.** Lines 4–5 follow the [Zsh Plugin Standard](https://github.com/zdharma/Zsh-100-Commits-Club/blob/master/Zsh-Plugin-Standard.adoc) for resolving `$0` so the plugin works under `zplug`, `zinit`, Oh-My-Zsh, manual sourcing, etc. Preserve this block when editing — it is the entry point contract with plugin managers.
- **Timestamp aliasing via `HIST_STAMPS`.** The `case ${HIST_STAMPS-}` block (lines 28–34) maps the user's `HIST_STAMPS` env var to an `fc` flag and aliases `history` to `zsh_history` with that flag. Adding a new format means adding a new branch here, not modifying `zsh_history`.
- **Defaults are conditional.** `HISTFILE`, `HISTSIZE`, and `SAVEHIST` are only set if unset / below the floor, so the plugin must not clobber values the user already configured. Keep this guard semantics when changing defaults.
- **`setopt`s are unconditional.** The history-behavior `setopt`s at the bottom are set every time the plugin loads. This is intentional — they define the plugin's purpose.

## Conventions

- Target Zsh (shebang is `#!/usr/bin/env zsh`); do not introduce Bash-only syntax.
- Use `builtin fc` rather than bare `fc` inside `zsh_history` to avoid recursing through the alias.
- Match the existing two-space indentation and lowercase function names.

## Testing changes manually

```zsh
# Load the plugin into the current shell
source ./zsh-history.plugin.zsh

# Exercise the wrapper
history          # list all history entries
history 10       # last 10 entries
history -l 1     # passthrough to `fc -l 1`
HIST_STAMPS="yyyy-mm-dd" source ./zsh-history.plugin.zsh && history
```
