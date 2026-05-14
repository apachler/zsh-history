# HAPPY-CODING.md — Engineering backlog

A persistent list of improvements, ideas, and deferred recommendations for `zsh-history`. The items in this file were intentionally **not** implemented during the initial audit because each had a tradeoff worth pausing on — too much complexity for the value, requires a maintainer decision, can't live in-tree, or sits outside the project's intentional scope.

This is a working document. As items land, delete them (or move to a `## Done` section if the rationale is worth keeping).

## Legend

**Priority** — `P1` ship this soon · `P2` good when time permits · `P3` nice-to-have / discoverability · `P4` only if a contributor specifically wants it

**Effort** — `S` < 30 min · `M` < 2 hours · `L` < 1 day · `XL` multi-day

**Impact** — one-line "what this gets us"

---

## Server-side settings (can't live in-tree)

These have to be toggled in the GitHub repo settings UI. They're listed here so they don't get forgotten.

### `S1` Enable branch protection on `main` — P1 · S

- **Rationale:** Without protection, anyone with write access (including a future co-maintainer or a compromised PAT) can push directly to `main`, bypassing CI and review. This is the single biggest gap between "feels professional" and "actually defensible."
- **How:** Settings → Branches → Add rule for `main`. Require: PR before merging, 1 approval, status checks `test`, `smoke`, `gitleaks` passing, branches up to date before merge, signed commits, linear history (optional), force-push disabled.
- **Impact:** Hardens the merge boundary. Also unblocks an OpenSSF Scorecard point.

### `S2` Enable private vulnerability reporting — P1 · S

- **Rationale:** `SECURITY.md` links to `/security/advisories/new`. That route only works when the feature is enabled.
- **How:** Settings → Code security → Private vulnerability reporting → Enable.
- **Impact:** The link in `SECURITY.md` becomes functional; reporters have a sanctioned private channel.

### `S3` Enable GitHub Discussions — P2 · S

- **Rationale:** `.github/ISSUE_TEMPLATE/config.yml` routes "question or discussion" to `/discussions`. If Discussions is off, that link 404s.
- **How:** Settings → General → Features → Discussions → Enable. Configure categories (Q&A, Ideas, Show and tell).
- **Impact:** Channels usage questions away from the issue tracker.

### `S4` Enable Dependabot security updates and grouped updates — P2 · S

- **Rationale:** The current `dependabot.yml` opens PRs for *version* updates. *Security* updates are a separate toggle and don't need a config file.
- **How:** Settings → Code security → Dependabot security updates → Enable. Also consider Dependabot version updates grouped: add `groups:` block to `dependabot.yml` so all GitHub Actions bumps land in one PR per week.
- **Impact:** Faster patch propagation; less PR noise.

### `S5` Auto-merge Dependabot PRs once checks pass — P3 · M

- **Rationale:** Actions updates are mechanical. After confirming tests pass, merging them by hand is a tax. Auto-merge keeps maintenance cost negligible.
- **How:** Settings → General → Pull Requests → Allow auto-merge. Add a small workflow that runs on `pull_request_target` from Dependabot and calls `gh pr merge --auto --squash`. Caveat: only safe with branch protection requiring CI to pass (see `S1`).
- **Impact:** ~zero-touch dependency upkeep.

---

## P1 — High value, ship soon

### `P1-1` Fix the `A && B || C` footgun at `zsh-history.plugin.zsh:91` — P1 · S

- **Current:** `[[ ${@[-1]-} = (-|)<-> ]] && builtin fc -l "$@" || builtin fc -l "$@" 1`
- **Problem:** Classic shell anti-pattern. If the `[[ ]]` test succeeds but `builtin fc -l "$@"` exits non-zero (malformed args, etc.), `builtin fc -l "$@" 1` *also* runs, duplicating output.
- **Fix:**
  ```zsh
  if [[ ${@[-1]-} = (-|)<-> ]]; then
    builtin fc -l "$@"
  else
    builtin fc -l "$@" 1
  fi
  ```
- **Impact:** Closes the only known correctness footgun. Add a test case where `fc -l` would fail to lock in the behavior.

### `P1-2` Run CI on a zsh version matrix — P1 · M

- **Rationale:** Right now CI runs whatever zsh ships on Ubuntu / macOS images. That's typically 5.8 / 5.9, but the floor is implicit. A regression that requires 5.9 wouldn't be caught for anyone still on 5.8.
- **Implementation:** Matrix on `zsh-version: [5.8, 5.9, latest]`. Install zsh from source for the explicit pins, or use a container with `zshenv` matching the desired version. Cheapest: keep ubuntu-latest + macos-latest, add `ubuntu-22.04` (older zsh) as a third leg.
- **Impact:** Locks in the "zsh 5.8+" claim in the README.

### `P1-3` Submit a SHA-pin pass for all actions — P1 · S

- **Rationale:** Currently `actions/checkout@v4` (tag) is used in four places, plus the Scorecard workflow is SHA-pinned. OpenSSF Scorecard scores mixed pinning lower than uniformly SHA-pinned. Dependabot keeps SHA pins fresh once they're in place.
- **Implementation:** Replace `@v4` with the current `actions/checkout` SHA (look up the latest release SHA at the time of the change) and add a `# v4.x.y` comment. Same for `gitleaks-action` (already pinned) and any new actions added later.
- **Tradeoff:** Slightly noisier Dependabot PRs (SHA bumps vs tag bumps), but Dependabot includes the changelog/release link in each so review cost is low.
- **Impact:** Higher Scorecard score; complete supply-chain pin coverage.

---

## P2 — Useful when time permits

### `P2-1` Dynamic coverage badge — P2 · M

- **Current:** `![coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)` is a static literal.
- **Rationale:** The badge can't drift below 100% because the CI gate would fail first, but it also can't go *up* past 100%, and it can't reflect a partial regression for a PR. A live badge is honest.
- **Implementation:** From `test.yml`, write a `coverage.json` shields.io endpoint JSON to a `badges` orphan branch (or a Gist). Update the README badge to `https://img.shields.io/endpoint?url=…coverage.json`. Use `schneegans/dynamic-badges-action`.
- **Impact:** Real-time coverage signal. Low practical value here (always 100%), so deprioritize unless coverage drops by design (added `nocov` regions).

### `P2-2` Typos linter — P2 · S

- **Tool:** `crate-ci/typos` action. Catches the kind of typos shellcheck *would* catch if it spoke zsh — variable names, comments, identifiers.
- **Rationale:** Zero false positives in practice, runs in <5s, configurable via `_typos.toml` if it ever finds an intentional non-word (e.g., "histfile" vs "histful").
- **Implementation:** Add a `typos.yml` workflow with `crate-ci/typos-action`.
- **Impact:** Catches embarrassing typos in `README`, `CLAUDE.md`, and comments.

### `P2-3` Add a `--help` flag — P2 · M

- **Rationale:** Currently the only way to learn flags is `man fc` (which doesn't cover the wrapper) or the README. A first-class `history --help` is what every CLI user reaches for.
- **Implementation:** New branch in `zsh_history`. Print a here-doc with flag synopsis. Test: assert presence of each flag in the output.
- **Impact:** Discoverability win for new users. Modest.

### `P2-4` Add `SUPPORT.md` — P2 · S

- **Rationale:** GitHub surfaces `SUPPORT.md` on the "where do I file an issue?" workflow. With Discussions enabled (see `S3`), it's the natural pointer.
- **Content:** One screen — "Got a bug? File an issue. Got a question? Discussions. Security? See SECURITY.md."
- **Impact:** Minor; reduces "wrong place" issues.

### `P2-5` Add `.github/labels.yml` and a labeler workflow — P3 · M

- **Rationale:** Issue/PR labels drift over time. `crazy-max/ghaction-github-labeler` lets you keep the canonical label set in-repo.
- **Implementation:** Define labels (`bug`, `enhancement`, `dependencies`, `documentation`, `security`, `good first issue`, `help wanted`). Add a workflow that syncs.
- **Impact:** Consistent labels. Low ROI for a small repo, but useful if external contribution picks up.

### `P2-6` Stale issues bot — P3 · S

- **Tool:** `actions/stale`. Auto-closes issues with no activity after N days, with a warning M days prior.
- **Tradeoff:** Useful for keeping the queue clean; can feel hostile to a casual reporter. If used, set generous thresholds (e.g., 90/120 days).
- **Impact:** Tidier backlog if/when issues accumulate.

### `P2-7` Document the `tests/coverage.zsh` heuristic in `CLAUDE.md` — P2 · S

- **Rationale:** The "what counts as an executable line" logic in `coverage.zsh` is an `awk` script that's intentionally conservative. A future contributor adding a new control-flow construct could be surprised when their lines aren't counted.
- **Implementation:** Add a sub-section to `CLAUDE.md` explaining the exclusion rules (lone braces, single-quoted multiline strings, `nocov` markers, function-definition lines) and pointing to the awk script.
- **Impact:** Reduces "why didn't my line count?" confusion.

---

## P3 — Discoverability, polish, ecosystem

### `P3-1` Asciinema cast in README — P3 · M

- **Rationale:** A 20-second cast of `history --top`, `history -s`, and the fzf widget is the highest-bandwidth explainer for what the plugin *does*. Static screenshots feel dated.
- **Implementation:** Record with `asciinema rec`, upload to asciinema.org, embed link in README under "Features." Alternative: a SVG terminal recording via `vhs`.
- **Impact:** Significantly improves the README's persuasion in the first 5 seconds. Big lift for adoption.

### `P3-2` Submit to `awesome-zsh-plugins` — P3 · S

- **Rationale:** That list is where most zsh users discover plugins. One-line PR to `unixorn/awesome-zsh-plugins/README.md`.
- **Prereq:** Cut a v1.0.0 tag first; entries with no release look unfinished.
- **Impact:** Real adoption signal.

### `P3-3` Homebrew tap or formula — P3 · L

- **Rationale:** macOS users often install zsh plugins through Homebrew if available, even though `git clone + source` works fine. A tap (`apachler/homebrew-zsh-history`) hosts the formula without polluting `homebrew-core`.
- **Tradeoff:** Maintenance: every release needs a tap PR. Solvable with `goreleaser`-style tooling but that's overkill for a single shell file.
- **Implementation:** Generate the formula in `release.yml`, push to the tap repo.
- **Impact:** Discoverability + frictionless install for the Homebrew crowd. Worth doing only after adoption signals warrant the maintenance.

### `P3-4` Nix flake — P3 · M

- **Rationale:** Nix users have asked for first-class flakes on similar plugins. Trivial flake exposing the plugin file as a package.
- **Implementation:** `flake.nix` with `packages.default = pkgs.stdenv.mkDerivation { … }` copying the plugin into `share/zsh/plugins/`.
- **Impact:** Niche but vocal user segment. Skip unless someone asks.

### `P3-5` `CITATION.cff` — P4 · S

- **Rationale:** Only worth it if you expect academic citation (you don't, this is a shell plugin).
- **Skip recommendation:** No.

### `P3-6` OpenSSF Best Practices self-assessment badge — P3 · M

- **Site:** bestpractices.coreinfrastructure.org
- **Rationale:** Adds a credible badge. Requires a ~30-minute self-assessment questionnaire.
- **Implementation:** Sign up, answer the questions (most are already true for this repo), copy badge URL into README.
- **Impact:** Adds an OpenSSF-issued badge separate from Scorecard. Useful for enterprise credibility.

---

## P4 — Explicitly considered, intentionally not done

Each of these came up during the audit. Listed here so future-you doesn't re-evaluate from scratch — and so anyone proposing one in a PR can see why it was deferred.

### `P4-1` CodeQL — skip

- **Reason:** CodeQL has no shell/zsh analyzer. Adding an empty workflow would lower the Scorecard score for "test failure" reasons or waste CI minutes scanning nothing.

### `P4-2` Docker / containerization — skip

- **Reason:** This is a zsh source file. There is nothing to containerize. A `Dockerfile FROM ubuntu RUN install zsh` would be a strict regression from `git clone`.

### `P4-3` semantic-release / release-please — skip

- **Reason:** The current `release.yml` is 30 lines, builds notes from `git log`, marks pre-releases by tag suffix. semantic-release would force a Node.js dependency and conventional commit enforcement. Net cost > net win for a project this size.

### `P4-4` Conventional commits enforcement (commitlint) — skip

- **Reason:** Increases contributor friction with no observable benefit. The current `release.yml` generates fine notes from any reasonable commit subject.

### `P4-5` shellcheck / shfmt — skip

- **Reason:** Neither has a zsh mode. Running them on `zsh-history.plugin.zsh` produces false positives because zsh-only constructs (`zparseopts -E -D`, `${(M)0:#/*}`, `${~var}`, `add-zsh-hook`) aren't recognized. Already noted in `CLAUDE.md`.

### `P4-6` SBOM (CycloneDX/SPDX) — skip

- **Reason:** Single dependency-free shell file. The SBOM would say "one shell script." No supply chain to model. Could revisit if the plugin ever bundles vendored helpers.

### `P4-7` SLSA provenance / sigstore signing of release artifacts — skip

- **Reason:** `release.yml` doesn't publish artifacts beyond a GitHub-built source tarball, which GitHub already signs at the commit level. Cosign-keyless of the tarball would be ceremony without consumer.

### `P4-8` Performance benchmarking workflow — skip

- **Reason:** Plugin is O(n) in history-file size and dominated by `awk`/`sort`. Microbench would measure libc, not us. Real concern would be startup time (sourcing this plugin should add < 5ms); if that ever regresses, a single `time` invocation in `smoke.yml` catches it.

### `P4-9` GOVERNANCE.md / ROADMAP.md — skip

- **Reason:** Premature for a solo-maintained plugin. Add when there's a second maintainer or external sponsor.

### `P4-10` `all-contributors` — skip

- **Reason:** Useful for projects with broad contribution surface. For a 167-line plugin with linear authorship, the bot adds more PR noise than it saves.

### `P4-11` Renovate as Dependabot alternative — skip

- **Reason:** Dependabot is sufficient; Renovate's main wins (grouping rules, custom regex managers) don't apply here. Don't switch.

### `P4-12` Comprehensive license-scanning (FOSSA / scancode) — skip

- **Reason:** Plugin is MIT-only and derives from another MIT project (Oh My Zsh's `lib/history.zsh`). No transitive license risk to scan.

---

## Pure ideas / explorations

Not committed to in any way; just thoughts a maintainer might find useful.

### Plugin precompilation via `zcompile`

- Optional "compile on first source" path could shave a millisecond or two off shell startup. Trade-off: complicates the simple "clone and source" mental model. Worth measuring before doing.

### Telemetry-free usage analytics

- A `history --report-usage` flag that produces a local digest (commands per day, top flags used by the user themselves). All local, no network. Could be a separate plugin (`zsh-history-stats`) to keep this one small.

### Reverse-engineering the `print -s` bypass

- `_zsh_history_filter` only catches interactive entry, not `print -s "secret"`. There's no zsh hook for that path. If one ever lands upstream, wire it in. Not a current bug — documented behaviour.

### Make `history -d` work for the running shell

- Zsh currently has no in-memory `$history` removal API. A patch to zsh upstream would unblock this; a workaround using `fc -W` + `exec zsh` is too disruptive. Park it.

---

## Done

(Move items here as they ship, keeping the rationale for future reference.)
