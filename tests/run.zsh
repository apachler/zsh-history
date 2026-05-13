#!/usr/bin/env zsh
# Test runner. Discovers tests/test_*.zsh and runs each in its own subshell.
# Each test file sources helpers.zsh and is expected to exit with its $_fail
# count (0 = green). On finish, prints a tally and exits nonzero if anything
# failed.

emulate -L zsh
setopt err_return no_unset pipe_fail

local self_dir=${0:A:h}
local plugin_file=${self_dir:h}/zsh-history.plugin.zsh
export PLUGIN_FILE=$plugin_file

if [[ ! -r $plugin_file ]]; then
  print -ru2 -- "run.zsh: cannot find plugin at $plugin_file"
  exit 2
fi

local -i total_pass=0 total_fail=0 file_failures=0
local -a failed_files

for test_file in $self_dir/test_*.zsh; do
  print -P "%F{magenta}── ${test_file:t} ──%f"
  local out
  if out=$(zsh -c "
    source \"$self_dir/helpers.zsh\"
    source \"$test_file\"
    print -- \"__TALLY__ \$_pass \$_fail\"
    exit \$_fail
  " 2>&1); then
    : # passed
  else
    (( file_failures++ ))
    failed_files+=$test_file
  fi
  # Print the file's output minus the tally marker
  print -- "${out%$'\n'__TALLY__*}"
  local tally=${out##*__TALLY__ }
  if [[ $tally = [0-9]##' '[0-9]## ]]; then
    total_pass+=${tally%% *}
    total_fail+=${tally##* }
  fi
done

print
print -P "%B═══ Results ═══%b"
print -P "  passed : %F{green}$total_pass%f"
print -P "  failed : %F{red}$total_fail%f"
print -P "  files  : ${#failed_files} of $(ls $self_dir/test_*.zsh | wc -l | tr -d ' ') failed"

if (( total_fail > 0 || file_failures > 0 )); then
  for f in $failed_files; do
    print -ru2 -- "  - ${f:t}"
  done
  exit 1
fi
exit 0
