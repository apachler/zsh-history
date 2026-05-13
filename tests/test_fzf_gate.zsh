# Coverage for the fzf opt-in widget block (~lines 148–166). All three
# preconditions are independently checked — the gate must remain a strict
# AND so the plugin stays a no-op for shells that didn't ask for fzf.

emulate -L zsh

local out

it "HIST_FZF unset → widget is NOT registered"
out=$(zsh -c "
  source $PLUGIN_FILE
  (( \${+functions[_zsh_history_fzf_widget]} )) && print yes || print no
")
assert_eq "$out" "no"

it "HIST_FZF=0 → widget is NOT registered"
out=$(HIST_FZF=0 zsh -c "
  source $PLUGIN_FILE
  (( \${+functions[_zsh_history_fzf_widget]} )) && print yes || print no
")
assert_eq "$out" "no"

it "HIST_FZF=1 but shell is non-interactive → widget is NOT registered"
out=$(HIST_FZF=1 zsh -c "
  source $PLUGIN_FILE
  (( \${+functions[_zsh_history_fzf_widget]} )) && print yes || print no
")
assert_eq "$out" "no"

# We can't reliably spin up an interactive zsh in CI to assert the positive
# case (it needs a TTY), but we can verify the gate's individual conditions
# are evaluated by simulating `fzf` and forcing the interactive option.
it "HIST_FZF=1 + fzf-on-PATH + -o interactive → widget IS registered"
local fake=$(mktemp -d)
print -- '#!/bin/sh' > "$fake/fzf"
chmod +x "$fake/fzf"
out=$(HIST_FZF=1 PATH="$fake:$PATH" zsh -ic "
  source $PLUGIN_FILE
  (( \${+functions[_zsh_history_fzf_widget]} )) && print yes || print no
" 2>/dev/null)
assert_eq "$out" "yes"
rm -rf "$fake"
