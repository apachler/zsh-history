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

# Run each test under xtrace, concatenating traces into a single file.
local merged=$trace_dir/merged.trace
: > "$merged"
for test_file in $self_dir/test_*.zsh; do
  PS4='+TRACE:%N:%i: ' zsh -x -c "
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

# Count executable lines in the plugin: skip blank, comment-only, and lines
# that are nothing but a closing brace / done / fi / esac / then keyword.
local executable_lines
executable_lines=$(grep -nvE '^\s*($|#|\}\s*$|\{\s*$|fi\s*$|done\s*$|esac\s*$|then\s*$|else\s*$|do\s*$)' "$plugin_file" \
                   | cut -d: -f1 | sort -un)
local total_count
total_count=$(print -- "$executable_lines" | grep -c .)

# Compute percentage (integer)
local pct=$(( hit_count * 100 / total_count ))

# Optionally identify missed lines for human review
if (( ${VERBOSE:-0} )); then
  comm -23 <(print -- "$executable_lines") <(print -- "$hit_lines") > "$trace_dir/missed"
  print "Missed lines:"
  while IFS= read -r ln; do
    print -- "  $plugin_base:$ln: $(sed -n "${ln}p" "$plugin_file")"
  done < "$trace_dir/missed"
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
