# ZSH History plugin

[![smoke](https://github.com/apachler/zsh-history/actions/workflows/smoke.yml/badge.svg)](https://github.com/apachler/zsh-history/actions/workflows/smoke.yml)
[![test](https://github.com/apachler/zsh-history/actions/workflows/test.yml/badge.svg)](https://github.com/apachler/zsh-history/actions/workflows/test.yml)
[![links](https://github.com/apachler/zsh-history/actions/workflows/links.yml/badge.svg)](https://github.com/apachler/zsh-history/actions/workflows/links.yml)
[![release](https://github.com/apachler/zsh-history/actions/workflows/release.yml/badge.svg)](https://github.com/apachler/zsh-history/actions/workflows/release.yml)
[![latest release](https://img.shields.io/github/v/release/apachler/zsh-history?sort=semver&display_name=tag)](https://github.com/apachler/zsh-history/releases/latest)
[![coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)](.github/workflows/test.yml)
[![license](https://img.shields.io/github/license/apachler/zsh-history)](LICENSE)
[![zsh](https://img.shields.io/badge/zsh-5.8%2B-brightgreen?logo=zsh)](https://www.zsh.org/)

A Zsh `history` wrapper, descended from Oh-My-Zsh's [`lib/history.zsh`](https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/history.zsh) and extended with search, delete, stats, sensitive-line filtering, and an opt-in fzf binding.

## Installation

### Oh My Zsh

Clone the repo into Oh My Zsh's custom plugins directory and add `zsh-history` to your `plugins=(…)` array in `.zshrc`:

```zsh
git clone https://github.com/apachler/zsh-history \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history"
```

```zsh
plugins=(… zsh-history)
```

### zplug

```zsh
zplug "apachler/zsh-history"
```

### zinit

```zsh
zinit light apachler/zsh-history
```

### antidote

Add to `.zsh_plugins.txt`:

```
apachler/zsh-history
```

### antigen

```zsh
antigen bundle apachler/zsh-history
```

### zgenom

```zsh
zgenom load apachler/zsh-history
```

### sheldon

Add to `plugins.toml`:

```toml
[plugins.zsh-history]
github = "apachler/zsh-history"
```

### Manual

```zsh
git clone https://github.com/apachler/zsh-history ~/.zsh/zsh-history
```

Then in `.zshrc`:

```zsh
source ~/.zsh/zsh-history/zsh-history.plugin.zsh
# Optional: enable the completion file
fpath=(~/.zsh/zsh-history/completions $fpath)
```

## Usage

```zsh
history                  # list all events (equivalent to `fc -l 1`)
history 50               # list from event 50 onwards
history -10              # last 10 events
history -l <fc args…>    # passthrough to `fc`
history -c               # truncate $HISTFILE
history -s <pattern>     # grep events for an extended-regex pattern
history -d <N>           # remove event N from $HISTFILE
history --top <N>        # show the N most-used commands (by first word)
```

## Configuration

All variables are optional. Set them in `.zshrc` *before* sourcing the plugin where noted.

| Variable             | Effect                                                                                                  |
| -------------------- | ------------------------------------------------------------------------------------------------------- |
| `HIST_STAMPS`        | Timestamp format for `history` output. Accepts `mm/dd/yyyy`, `dd.mm.yyyy`, `yyyy-mm-dd`, or a literal `strftime` string. |
| `HISTFILE`           | History file path. Defaults to `$XDG_STATE_HOME/zsh/history` when `XDG_STATE_HOME` is set, otherwise `~/.zsh_history`. |
| `HISTSIZE`           | In-memory event count. Raised to `50000` if lower / unset.                                              |
| `SAVEHIST`           | Events persisted to `HISTFILE`. Raised to `10000` if lower / unset.                                     |
| `ZSH_HISTORY_IGNORE` | Zsh glob — interactively-entered commands matching this are dropped from both the in-memory list and `HISTFILE`. Example: `'(*--token=*|*PASSWORD=*|*AWS_SECRET*)'`. |
| `HIST_FZF`           | Set to `1` *before* sourcing to bind `^R` to an fzf history picker (requires `fzf` on `$PATH`). Off by default. |

### `setopt`s unconditionally applied

`extended_history`, `hist_expire_dups_first`, `hist_ignore_dups`, `hist_ignore_space`, `hist_reduce_blanks`, `hist_verify`, `share_history`.

## Caveats

- `history -d N` rewrites `HISTFILE`, but zsh exposes no API to remove an entry from the running shell's in-memory list. The deletion is reflected in the next shell. Multi-line entries are refused to avoid mis-deleting unrelated commands.
- `history -s` and `history --top` read from disk where appropriate; if `share_history` is on, recent commands from sibling shells appear after the next prompt.
