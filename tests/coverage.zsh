#!/usr/bin/env zsh
# Computes line coverage for zsh-history.plugin.zsh by running every test
# under `setopt xtrace` and collecting the set of (file:lineno) tuples that
# zsh actually executed. Coverage = unique lines hit / executable lines.
#
# "Executable" = lines that are not blank, not pure-comment, not lone braces.
# That's an approximation but it matches what xtrace can ever report.
#
# Exits 0 if coverage >= ${COVERAGE_MIN:-80} percent, nonzero otherwise.

emulate -L zsh
setopt err_exit no_unset pipe_fail

local self_dir=${0:A:h}
local plugin_file=${self_dir:h}/zsh-history.plugin.zsh
local plugin_base=${plugin_file:t}

local trace_dir
trace_dir=$(mktemp -d)
trap "rm -rf $trace_dir" EXIT

# Trick: drop a .zshenv into a temp ZDOTDIR that enables xtrace with a
# tagged PS4. Every zsh subshell (including the nested ones tests use to
# isolate plugin state) reads .zshenv on startup, so the plugin's lines get
# traced even though we never modify the test files.
cat > "$trace_dir/.zshenv" <<'EOZ'
PS4='+TRACE:%x:%I: '
setopt xtrace
EOZ
export ZDOTDIR=$trace_dir

local merged=$trace_dir/merged.trace
: > "$merged"
export COVERAGE_TRACE=$merged   # picked up by helpers.zsh's `quiet` so tests
                                # route their suppressed stderr into the trace
for test_file in $self_dir/test_*.zsh; do
  zsh -c "
    source \"$self_dir/helpers.zsh\"
    export PLUGIN_FILE=\"$plugin_file\"
    source \"$test_file\"
  " 2>>"$merged" >/dev/null || true
done

# Collect unique line numbers seen in the plugin file. zsh writes %N as either
# the relative path used at source-time or an absolute path; match on basename.
local hit_lines
hit_lines=$(grep -oE "\+TRACE:[^:]*${plugin_base}:[0-9]+:" "$merged" \
            | grep -oE ':[0-9]+:$' \
            | tr -d ':' \
            | sort -un)

local hit_count
hit_count=$(print -- "$hit_lines" | grep -c . || true)

# Compute the set of "executable" lines in the plugin. A line is executable
# only if zsh would emit an xtrace entry for it, which excludes:
#   - blanks and comment-only lines
#   - lone keyword / brace lines (fi/done/esac/then/else/do/{/})
#   - the content of multi-line single-quoted strings (awk script bodies)
#   - regions explicitly marked `# nocov-start` … `# nocov-end`
local executable_lines
executable_lines=$(awk '
  BEGIN { inquote = 0; nocov = 0 }
  # nocov markers go first so comments embedding them are still recognized
  /# nocov-start/ { nocov = 1; next }
  /# nocov-end/   { nocov = 0; next }
  nocov { next }
  {
    # Strip inline comments before doing any quote analysis, so apostrophes
    # in comments ("don'\''t", "we'\''re") don'\''t corrupt the state.
    clean = $0
    sub(/[[:space:]]*#.*$/, "", clean)
  }
  inquote {
    if (index(clean, "'\''") > 0) inquote = 0
    next
  }
  {
    n = gsub(/'\''/, "'\''", clean)
    if (n % 2 == 1) {
      inquote = 1
      print NR; next
    }
  }
  /^[[:space:]]*($|#|\}[[:space:]]*$|\{[[:space:]]*$|fi[[:space:]]*$|done[[:space:]]*$|esac[[:space:]]*$|then[[:space:]]*$|else[[:space:]]*$|do[[:space:]]*$)/ { next }
  /^function[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\{?[[:space:]]*$/ { next }
  { print NR }
' "$plugin_file" | sort -un)
local total_count
total_count=$(print -- "$executable_lines" | grep -c .)

# Compute percentage (integer). Clamp at 100 because xtrace occasionally
# reports lines that the executable-line heuristic conservatively excluded
# (e.g. a `case` clause whose pattern line wasn't deemed executable on its own).
local pct=$(( hit_count * 100 / total_count ))
(( pct > 100 )) && pct=100

# Optionally identify missed lines for human review
if (( ${VERBOSE:-0} )); then
  # `comm` requires lexicographically-sorted input. Re-sort with `sort` (no -n)
  # so the comparison is well-defined regardless of numeric width.
  print -- "$executable_lines" | sort -u > "$trace_dir/exec.sorted"
  print -- "$hit_lines"        | sort -u > "$trace_dir/hit.sorted"
  comm -23 "$trace_dir/exec.sorted" "$trace_dir/hit.sorted" > "$trace_dir/missed"
  if [[ -s $trace_dir/missed ]]; then
    print "Missed lines:"
    while IFS= read -r ln; do
      print -- "  $plugin_base:$ln: $(sed -n "${ln}p" "$plugin_file")"
    done < <(sort -n "$trace_dir/missed")
  else
    print "All executable lines covered."
  fi
fi

local min=${COVERAGE_MIN:-80}
print -- "Coverage: $hit_count / $total_count = ${pct}%  (threshold: ${min}%)"

if [[ -n ${GITHUB_STEP_SUMMARY-} ]]; then
  {
    print -- "### Test coverage"
    print -- ""
    print -- "| metric | value |"
    print -- "| ------ | ----- |"
    print -- "| lines hit | $hit_count |"
    print -- "| lines executable | $total_count |"
    print -- "| **coverage** | **${pct}%** |"
    print -- "| threshold | ${min}% |"
  } >> "$GITHUB_STEP_SUMMARY"
fi

(( pct >= min ))
