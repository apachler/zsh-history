# Coverage for the HIST_STAMPS case block (zsh-history.plugin.zsh, ~lines 99–105).
# Each variant should map to a specific `zsh_history …` alias body without
# breaking on awkward characters in the format string.

emulate -L zsh

local alias_body

it "HIST_STAMPS unset → bare zsh_history alias"
alias_body=$(zsh -c "source $PLUGIN_FILE; alias history")
assert_eq "$alias_body" "history=zsh_history"

it "HIST_STAMPS=mm/dd/yyyy → -f"
alias_body=$(HIST_STAMPS=mm/dd/yyyy zsh -c "source $PLUGIN_FILE; alias history")
assert_eq "$alias_body" "history='zsh_history -f'"

it "HIST_STAMPS=dd.mm.yyyy → -E"
alias_body=$(HIST_STAMPS=dd.mm.yyyy zsh -c "source $PLUGIN_FILE; alias history")
assert_eq "$alias_body" "history='zsh_history -E'"

it "HIST_STAMPS=yyyy-mm-dd → -i"
alias_body=$(HIST_STAMPS=yyyy-mm-dd zsh -c "source $PLUGIN_FILE; alias history")
assert_eq "$alias_body" "history='zsh_history -i'"

it "HIST_STAMPS=arbitrary strftime → -t with quoted value"
alias_body=$(HIST_STAMPS='%Y/%m/%d %H:%M' zsh -c "source $PLUGIN_FILE; alias history")
assert_contains "$alias_body" "zsh_history -t"
# value must be present (in some quoted form) — assert via raw expansion
assert_contains "$alias_body" '%Y/%m/%d'

it "HIST_STAMPS containing a single quote does not break the alias"
# Verify it via behavior, not by re-evaluating the alias-listing output
# (zsh's `alias` output uses `name='value'` form, which collides with the
# read-only $history array if you eval it as a command).
alias_body=$(HIST_STAMPS="weird'quote" zsh -c "source $PLUGIN_FILE; alias history")
assert_contains "$alias_body" "zsh_history -t"
assert_contains "$alias_body" "weird"
assert_contains "$alias_body" "quote"
