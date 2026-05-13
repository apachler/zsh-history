#!/usr/bin/env zsh
# Standardized $0 handling, following:
# https://github.com/zdharma/Zsh-100-Commits-Club/blob/master/Zsh-Plugin-Standard.adoc
0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"


function zsh_history {
  local clear list
  local -a search_arg delete_arg
  # -E keeps unknown flags (e.g. the HIST_STAMPS-derived `-f`/`-E`/`-i`/`-t`)
  # in $@ so they pass through to `fc`; -D strips the flags we recognize.
  zparseopts -E -D c=clear l=list s+:=search_arg d+:=delete_arg

  if [[ -n "$clear" ]]; then
    # if -c provided, truncate the history file and push a fresh fc stack
    # so the current shell stops writing into the old file contents
    : >| "$HISTFILE"
    fc -p "$HISTFILE"
    print -ru2 -- "History file deleted."
  elif [[ -n "$list" ]]; then
    # if -l provided, run as if calling `fc' directly (any stamp flag in $@
    # passes through)
    builtin fc -l "$@"
  elif (( ${#search_arg} )); then
    # `history -s PATTERN`: list all events and filter through grep.
    # PATTERN is an extended-regex. Color is auto when stdout is a tty.
    local pattern=${search_arg[2]}
    builtin fc -l "$@" 1 | grep --color=auto -E -- "$pattern"
  elif (( ${#delete_arg} )); then
    # `history -d N`: delete event N from HISTFILE and reload.
    # Looks the command up in the in-memory $history array (it must already
    # be loaded — i.e. N belongs to the current shell's view), then rewrites
    # the file with the last occurrence of that command removed. Multi-line
    # entries are refused to avoid mis-deleting unrelated events.
    local n=${delete_arg[2]}
    if [[ $n != <-> ]]; then
      print -ru2 -- "history: -d expects a positive event number, got: $n"
      return 1
    fi
    local cmd=${history[$n]-}
    if [[ -z $cmd ]]; then
      print -ru2 -- "history: no event $n in current shell history"
      return 1
    fi
    if [[ $cmd = *$'\n'* ]]; then
      print -ru2 -- "history: refusing to delete multi-line event $n"
      return 1
    fi
    builtin fc -W
    local tmp=${HISTFILE}.tmp.$$
    awk -v needle=";$cmd" '
      { lines[NR] = $0 }
      END {
        nlen = length(needle)
        for (i = NR; i >= 1 && !target; i--) {
          if (length(lines[i]) >= nlen &&
              substr(lines[i], length(lines[i]) - nlen + 1) == needle) {
            target = i
          }
        }
        for (i = 1; i <= NR; i++) if (i != target) print lines[i]
      }
    ' "$HISTFILE" > "$tmp" || { rm -f "$tmp"; return 1 }
    mv -- "$tmp" "$HISTFILE"
    # NOTE: zsh has no API to remove an entry from the in-memory history list.
    # The file is now clean; the current shell's $history will catch up the
    # next time it loads HISTFILE (i.e. in a new shell).
    print -ru2 -- "History event $n removed from $HISTFILE."
  else
    # unless a numeric arg is provided, show all events (starting from 1).
    # Accept bare digits or a negative-prefixed count (e.g. `history -10`).
    [[ ${@[-1]-} = (-|)<-> ]] && builtin fc -l "$@" || builtin fc -l "$@" 1
  fi
}


# Timestamp format. Drop any pre-existing alias so we don't stack on top of
# one another when the plugin is re-sourced (or another plugin defined one).
unalias history 2>/dev/null
case ${HIST_STAMPS-} in
  "mm/dd/yyyy") alias history='zsh_history -f' ;;
  "dd.mm.yyyy") alias history='zsh_history -E' ;;
  "yyyy-mm-dd") alias history='zsh_history -i' ;;
  "") alias history='zsh_history' ;;
  *) alias history="zsh_history -t ${(q)HIST_STAMPS}" ;;
esac

# History file configuration. Honor XDG_STATE_HOME when set (XDG Base Directory
# spec) but fall back to ~/.zsh_history for compatibility with existing setups.
if [[ -z "${HISTFILE-}" ]]; then
  if [[ -n "${XDG_STATE_HOME-}" && -d "$XDG_STATE_HOME" ]]; then
    HISTFILE="$XDG_STATE_HOME/zsh/history"
    [[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"
  else
    HISTFILE="$HOME/.zsh_history"
  fi
fi
[[ ${HISTSIZE:-0} -lt 50000 ]] && HISTSIZE=50000
[[ ${SAVEHIST:-0} -lt 10000 ]] && SAVEHIST=10000

# History command configuration
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_reduce_blanks     # collapse internal whitespace before saving
setopt hist_verify            # show command with history expansion to user before running it
setopt share_history          # share command history data
