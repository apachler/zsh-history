#!/usr/bin/env zsh
# Tiny assertion helpers for the test suite. No third-party framework.
#
# Each test file sources this header, calls `it "what is being tested"` to
# name a case, and then makes any number of `assert_*` calls. At the end of
# the file the runner reads $_pass / $_fail to tally. Failures print to
# stderr and increment $_fail; the file's exit code is the failure count.

emulate -L zsh
typeset -gi _pass=0 _fail=0
typeset -g  _it=""

function it {
  _it="$*"
  print -P "  • %F{cyan}$*%f"
}

function _ok   { (( _pass++ )) }
function _bad  {
  (( _fail++ ))
  print -ru2 -- "    ✗ ${_it:-(no description)}: $*"
}

function assert_eq {
  # assert_eq <actual> <expected> [message]
  [[ "$1" = "$2" ]] && _ok || _bad "expected '$2', got '$1'${3:+ — $3}"
}

function assert_neq {
  [[ "$1" != "$2" ]] && _ok || _bad "expected NOT '$2', got '$1'${3:+ — $3}"
}

function assert_contains {
  # assert_contains <haystack> <needle>
  [[ "$1" == *"$2"* ]] && _ok || _bad "expected to contain '$2', got: '$1'"
}

function assert_not_contains {
  [[ "$1" != *"$2"* ]] && _ok || _bad "expected NOT to contain '$2', got: '$1'"
}

function assert_match {
  # assert_match <string> <zsh-glob>
  [[ "$1" == ${~2} ]] && _ok || _bad "expected to match pattern '$2', got: '$1'"
}

function assert_rc {
  # assert_rc <expected-rc> -- <cmd...>
  local want=$1; shift
  [[ $1 = -- ]] && shift
  "$@" >/dev/null 2>&1
  local got=$?
  [[ $got -eq $want ]] && _ok || _bad "expected rc=$want, got rc=$got from: $*"
}

function assert_file_contains {
  local file=$1 needle=$2
  if [[ ! -r $file ]]; then _bad "no readable file: $file"; return; fi
  if grep -qF -- "$needle" "$file"; then _ok
  else _bad "file $file does not contain '$needle'"
  fi
}

function assert_file_not_contains {
  local file=$1 needle=$2
  if [[ ! -r $file ]]; then _bad "no readable file: $file"; return; fi
  if grep -qF -- "$needle" "$file"; then _bad "file $file unexpectedly contains '$needle'"
  else _ok
  fi
}

# Run a command in a fresh interactive-ish zsh subshell with the plugin
# sourced. Returns stdout; sets reply to (stdout stderr rc) via $? being the
# subshell rc. Used so tests don't pollute each other's options/aliases.
function run_with_plugin {
  # $1: shell snippet to run AFTER sourcing the plugin
  local snippet=$1
  zsh -c "
    source \"$PLUGIN_FILE\"
    $snippet
  "
}

# A fresh, isolated HISTFILE for a single test. Caller is responsible for
# cleanup via `rm -f \$HISTFILE`.
function fresh_histfile {
  local f
  f=$(mktemp)
  print -- "$f"
}
