# Security Policy

## Supported versions

Security fixes target the latest tagged release on `main`. Older tags are not back-patched.

## Reporting a vulnerability

Please **do not** open a public issue for security reports.

Use GitHub's [private vulnerability reporting](https://github.com/apachler/zsh-history/security/advisories/new) instead. If that's unavailable, email `apachler@paan-systems.com` with:

- a description of the issue and its impact,
- steps to reproduce (a minimal `.zshrc` snippet is ideal), and
- the plugin version (tag or commit SHA) you tested against.

You can expect:

- an acknowledgement within 72 hours,
- a fix or mitigation plan within 14 days for confirmed issues, and
- a coordinated disclosure window once a patch is ready.

## Scope

In scope:

- Code execution via crafted `HIST_STAMPS`, `ZSH_HISTORY_IGNORE`, `HISTFILE`, or other plugin-read environment variables.
- Information disclosure through `history -s`, `history -d`, `history --top`, or the fzf widget.
- Supply-chain issues in the plugin file, completions, or CI workflows.

Out of scope:

- Issues in zsh itself, `fc`, `awk`, `grep`, `fzf`, or other upstream tools.
- Local attackers who already have shell access (this plugin assumes a trusted shell).
- Sensitive data ending up in `$HISTFILE` despite `ZSH_HISTORY_IGNORE` — the filter is a hardening helper, not a guarantee.
