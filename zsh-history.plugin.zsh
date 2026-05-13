#!/usr/bin/env zsh
# Standardized $0 handling, following:
# https://github.com/zdharma/Zsh-100-Commits-Club/blob/master/Zsh-Plugin-Standard.adoc
0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"


function zsh_history {
  local clear list
  zparseopts -E c=clear l=list

  if [[ -n "$clear" ]]; then
    # if -c provided, truncate the history file and push a fresh fc stack
    # so the current shell stops writing into the old file contents
    : >| "$HISTFILE"
    fc -p "$HISTFILE"
    print -ru2 -- "History file deleted."
  elif [[ -n "$list" ]]; then
    # if -l provided, run as if calling `fc' directly
    builtin fc "$@"
  else
    # unless a numeric arg is provided, show all events (starting from 1).
    # Accept bare digits or a negative-prefixed count (e.g. `history -10`).
    [[ ${@[-1]-} = (-|)<-> ]] && builtin fc -l "$@" || builtin fc -l "$@" 1
  fi
}


# Timestamp format
case ${HIST_STAMPS-} in
  "mm/dd/yyyy") alias history='zsh_history -f' ;;
  "dd.mm.yyyy") alias history='zsh_history -E' ;;
  "yyyy-mm-dd") alias history='zsh_history -i' ;;
  "") alias history='zsh_history' ;;
  *) alias history="zsh_history -t ${(q)HIST_STAMPS}" ;;
esac

# History file configuration
[[ -z "${HISTFILE-}" ]] && HISTFILE="$HOME/.zsh_history"
[[ ${HISTSIZE:-0} -lt 50000 ]] && HISTSIZE=50000
[[ ${SAVEHIST:-0} -lt 10000 ]] && SAVEHIST=10000

# History command configuration
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt share_history          # share command history data
