# Coverage for the main zsh_history dispatch (~lines 8–93): -c, -l, -s, -d,
# --top, and the default-listing branch (with bare / numeric / negative arg).

emulate -L zsh

local hf=$(mktemp)
cat > "$hf" <<'EOF'
: 1700000001:0;echo alpha
: 1700000002:0;git status
: 1700000003:0;curl --token=SECRET https://example.com
: 1700000004:0;ls -la
: 1700000005:0;echo bravo
EOF

local out

it "bare 'history' lists every event from 1"
out=$(zsh -c "
  setopt extended_history
  HISTFILE=$hf
  fc -R \$HISTFILE
  source $PLUGIN_FILE
  zsh_history
")
assert_contains "$out" "echo alpha"
assert_contains "$out" "echo bravo"

it "'history N' starts the listing at event N"
out=$(zsh -c "
  setopt extended_history
  HISTFILE=$hf
  fc -R \$HISTFILE
  source $PLUGIN_FILE
  zsh_history 3
")
assert_not_contains "$out" "echo alpha"
assert_contains "$out" "ls -la"

it "'history -N' goes through the numeric branch (negative form)"
# `fc -l -N`'s exact slice depends on the shell's history options, so we
# only verify the plugin's dispatch: a negative-numeric trailing arg must
# reach `fc -l "$@"` (not `fc -l "$@" 1`) and produce non-empty output.
out=$(zsh -c "
  setopt extended_history
  HISTFILE=$hf
  fc -R \$HISTFILE
  source $PLUGIN_FILE
  zsh_history -2
")
assert_neq "$out" ""

it "'history -l 1' is a passthrough to fc -l"
out=$(zsh -c "
  setopt extended_history
  HISTFILE=$hf
  fc -R \$HISTFILE
  source $PLUGIN_FILE
  zsh_history -l 1
")
assert_contains "$out" "echo alpha"

it "'history -s PATTERN' filters via grep"
out=$(zsh -c "
  setopt extended_history
  HISTFILE=$hf
  fc -R \$HISTFILE
  source $PLUGIN_FILE
  zsh_history -s 'echo'
")
assert_contains "$out" "echo alpha"
assert_contains "$out" "echo bravo"
assert_not_contains "$out" "ls -la"

it "'history -s' with no matches exits nonzero"
zsh -c "
  setopt extended_history
  HISTFILE=$hf
  fc -R \$HISTFILE
  source $PLUGIN_FILE
  zsh_history -s 'definitely-not-in-history' >/dev/null 2>&1
"
local rc=$?
[[ $rc -ne 0 ]] && _ok || _bad "expected nonzero rc for unmatched search, got $rc"

# ---- delete ----
it "'history -d N' removes the target line from HISTFILE"
local target_hf=$(mktemp)
cp "$hf" "$target_hf"
zsh -c "
  setopt extended_history
  HISTFILE=$target_hf
  fc -R \$HISTFILE
  source $PLUGIN_FILE
  zsh_history -d 3
" >/dev/null 2>>"${COVERAGE_TRACE:-/dev/null}"
assert_file_not_contains "$target_hf" "curl --token=SECRET"
assert_file_contains "$target_hf" "echo alpha"
assert_file_contains "$target_hf" "ls -la"
rm -f "$target_hf"

it "'history -d <non-numeric>' rejects with rc=1"
zsh -c "
  setopt extended_history
  HISTFILE=$hf
  fc -R \$HISTFILE
  source $PLUGIN_FILE
  zsh_history -d abc
" 2>>"${COVERAGE_TRACE:-/dev/null}"
[[ $? -eq 1 ]] && _ok || _bad "expected rc=1 for non-numeric -d"

it "'history -d <missing>' rejects when event does not exist"
zsh -c "
  setopt extended_history
  HISTFILE=$hf
  fc -R \$HISTFILE
  source $PLUGIN_FILE
  zsh_history -d 9999
" 2>>"${COVERAGE_TRACE:-/dev/null}"
[[ $? -eq 1 ]] && _ok || _bad "expected rc=1 for missing event"

it "'history -d N' refuses multi-line events"
local ml_hf=$(mktemp)
# Build a HISTFILE where event 2 is a multi-line command (backslash continuation
# becomes a literal newline in the stored history line).
print -r -- ': 1700000010:0;echo single' > "$ml_hf"
print -r -- ': 1700000011:0;echo first\\' >> "$ml_hf"
print -r -- 'second line' >> "$ml_hf"
zsh -c "
  setopt extended_history
  HISTFILE=$ml_hf
  fc -R \$HISTFILE
  source $PLUGIN_FILE
  zsh_history -d 2
" 2>>"${COVERAGE_TRACE:-/dev/null}"
[[ $? -eq 1 ]] && _ok || _bad "expected rc=1 when deleting a multi-line event"
# The file must not have been modified
assert_file_contains "$ml_hf" "echo first"
assert_file_contains "$ml_hf" "second line"
rm -f "$ml_hf"

# ---- top ----
it "'history --top N' ranks by first word, descending count"
out=$(zsh -c "
  setopt extended_history
  HISTFILE=$hf
  fc -R \$HISTFILE
  source $PLUGIN_FILE
  zsh_history --top 5
")
# 'echo' twice, everything else once → echo on top
local first=$(print -r -- "$out" | sed -n '1p' | awk '{print $2}')
assert_eq "$first" "echo"

it "'history --top <non-numeric>' rejects with rc=1"
zsh -c "
  HISTFILE=$hf
  source $PLUGIN_FILE
  zsh_history --top abc
" 2>>"${COVERAGE_TRACE:-/dev/null}"
[[ $? -eq 1 ]] && _ok || _bad "expected rc=1 for non-numeric --top"

# ---- clear ----
it "'history -c' truncates HISTFILE"
local clear_hf=$(mktemp)
print -- "some content" > "$clear_hf"
zsh -c "
  HISTFILE=$clear_hf
  source $PLUGIN_FILE
  zsh_history -c
" 2>>"${COVERAGE_TRACE:-/dev/null}"
local size=$(wc -c < "$clear_hf" | tr -d ' ')
assert_eq "$size" "0"
rm -f "$clear_hf"

rm -f "$hf"
