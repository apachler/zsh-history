# Coverage for the HISTFILE / HISTSIZE / SAVEHIST default block (~lines
# 109–118) and the unalias guard (~line 98). Also covers hist_reduce_blanks
# and the rest of the unconditional setopt block (~lines 121–127).

emulate -L zsh

local out

it "HISTSIZE defaults to 50000 when unset"
out=$(env -u HISTSIZE -u SAVEHIST -u HISTFILE zsh -c "source $PLUGIN_FILE; print \$HISTSIZE")
assert_eq "$out" "50000"

it "SAVEHIST defaults to 10000 when unset"
out=$(env -u HISTSIZE -u SAVEHIST -u HISTFILE zsh -c "source $PLUGIN_FILE; print \$SAVEHIST")
assert_eq "$out" "10000"

it "HISTSIZE already high is not lowered"
out=$(HISTSIZE=999999 zsh -c "source $PLUGIN_FILE; print \$HISTSIZE")
assert_eq "$out" "999999"

it "SAVEHIST already high is not lowered"
out=$(SAVEHIST=999999 zsh -c "source $PLUGIN_FILE; print \$SAVEHIST")
assert_eq "$out" "999999"

it "HISTSIZE below the floor is bumped"
out=$(HISTSIZE=10 zsh -c "source $PLUGIN_FILE; print \$HISTSIZE")
assert_eq "$out" "50000"

it "Unset HISTFILE falls back to ~/.zsh_history"
out=$(env -u HISTFILE -u XDG_STATE_HOME zsh -c "source $PLUGIN_FILE; print \$HISTFILE")
assert_match "$out" '*/.zsh_history'

it "Set HISTFILE is respected"
out=$(HISTFILE=/tmp/custom-hist zsh -c "source $PLUGIN_FILE; print \$HISTFILE")
assert_eq "$out" "/tmp/custom-hist"

it "XDG_STATE_HOME branch (dir exists)"
local xdg
xdg=$(mktemp -d)
out=$(env -u HISTFILE XDG_STATE_HOME=$xdg zsh -c "source $PLUGIN_FILE; print \$HISTFILE")
assert_eq "$out" "$xdg/zsh/history"
rm -rf "$xdg"

it "Pre-existing history alias from another plugin gets replaced"
out=$(zsh -c 'alias history="echo PREEXISTING"; source '"$PLUGIN_FILE"'; alias history')
assert_eq "$out" "history=zsh_history"

it "Plugin enables hist_reduce_blanks"
out=$(zsh -c "source $PLUGIN_FILE; [[ -o hist_reduce_blanks ]] && print on")
assert_eq "$out" "on"

it "Plugin enables share_history"
out=$(zsh -c "source $PLUGIN_FILE; [[ -o share_history ]] && print on")
assert_eq "$out" "on"

it "Plugin enables extended_history"
out=$(zsh -c "source $PLUGIN_FILE; [[ -o extended_history ]] && print on")
assert_eq "$out" "on"
