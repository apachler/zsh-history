# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Released versions are also generated automatically from commit subjects by `.github/workflows/release.yml` — this file is the human-curated summary.

## [Unreleased]

### Added
- `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `CODEOWNERS`, issue/PR templates.
- OpenSSF Scorecard and gitleaks CI workflows.
- `.editorconfig`, `.gitattributes` (LF-only, `export-ignore` slimmer release tarball), `.gitignore`.
- `.pre-commit-config.yaml` for local hygiene checks.

### Changed
- All workflows now run with `permissions: read-all` at the top level and use `concurrency:` to cancel superseded runs.
- `actions/checkout` pinned to a commit SHA; dependabot keeps it fresh.
- `lychee` link-checker pinned to a specific release in `links.yml`.

[Unreleased]: https://github.com/apachler/zsh-history/compare/HEAD...HEAD
