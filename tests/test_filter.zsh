# Coverage for the zshaddhistory filter (_zsh_history_filter, ~lines 134–143).
# The hook is registered via add-zsh-hook; we exercise the function directly
# because zshaddhistory only fires for interactively-typed commands and that
# can't be reproduced from a non-interactive subshell.

emulate -L zsh

# helper: assert rc of the filter in a fresh subshell
local rc

it "no ZSH_HISTORY_IGNORE → all commands accepted (rc=0)"
zsh -c "source $PLUGIN_FILE; unset ZSH_HISTORY_IGNORE; _zsh_history_filter 'curl --token=ABC'"
[[ $? -eq 0 ]] && _ok || _bad "expected rc=0 with no IGNORE pattern"

it "matching pattern → reject with rc=1"
zsh -c "
  source $PLUGIN_FILE
  ZSH_HISTORY_IGNORE='(*--token=*|*PASSWORD=*)'
  _zsh_history_filter 'curl --token=ABC https://example.com'
"
[[ $? -eq 1 ]] && _ok || _bad "expected rc=1 for matching token line"

it "PASSWORD branch in the IGNORE alternation rejects"
zsh -c "
  source $PLUGIN_FILE
  ZSH_HISTORY_IGNORE='(*--token=*|*PASSWORD=*)'
  _zsh_history_filter 'export PASSWORD=hunter2'
"
[[ $? -eq 1 ]] && _ok || _bad "expected rc=1 for PASSWORD line"

it "non-matching command passes through (rc=0)"
zsh -c "
  source $PLUGIN_FILE
  ZSH_HISTORY_IGNORE='(*--token=*|*PASSWORD=*)'
  _zsh_history_filter 'git status'
"
[[ $? -eq 0 ]] && _ok || _bad "expected rc=0 for innocuous command"

it "trailing newline on the command is stripped before matching"
zsh -c "
  source $PLUGIN_FILE
  ZSH_HISTORY_IGNORE='*--secret*'
  _zsh_history_filter 'curl --secret=XYZ
'
"
[[ $? -eq 1 ]] && _ok || _bad "expected rc=1 even with trailing newline"

it "filter is registered as a zshaddhistory hook"
local hooks=$(zsh -c "source $PLUGIN_FILE; print \${zshaddhistory_functions[*]-(unset)}")
assert_contains "$hooks" "_zsh_history_filter"
