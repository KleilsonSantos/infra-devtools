# ADR-0002: Canonical SemVer, tags, and GitHub Releases

- **Status:** Accepted
- **Date:** 2026-09-30
- **Deciders:** Kleilson dos Santos

## Context

`infra-devtools` documents a release workflow in `HELP.md` (`VERSION` as SSOT, bump scripts, git tags), but runtime evidence showed:

- **zero** `vX.Y.Z` tags and **zero** GitHub Releases
- version skew: `VERSION` / `sonar.projectVersion` = `1.2.9` vs `package.json` = `1.4.0`
- `scripts/check-version-alignment.sh` required a package.json bump on every commit (anti-pattern)

AIOS provides a proven release *discipline* (annotated tags, CHANGELOG section, anti-drift gate after last tag) without requiring us to copy product cadence or gitmoji.

ADR-0001 established `feature → sandbox → main`. Releases must attach to that flow.

## Decision

### Source of truth

| File | Role |
|------|------|
| `VERSION` | **SSOT** (plain `MAJOR.MINOR.PATCH`) |
| `package.json` `version` | Must equal `VERSION` |
| `sonar-project.properties` `sonar.projectVersion` | Must equal `VERSION` |
| `CHANGELOG.md` | Must contain `## [X.Y.Z]` for each released version |

### When to release

```text
work → sandbox → promote → main
                              │
                              ▼
                    chore(release): bump VERSION
                    (or release PR targeting main after promote)
                              │
                              ▼
                    annotated tag vX.Y.Z + gh release
```

1. **Never** tag from a feature branch or from `sandbox`.
2. Aggregate releaseable work; do **not** require a SemVer bump on every feature PR.
3. Bump types: patch / minor / major (Conventional Commits inform the choice).
4. Tag format: annotated `vMAJOR.MINOR.PATCH` only.
5. GitHub Release notes reference the CHANGELOG section.

### Skew resolution (this ADR)

Treat `1.2.9` as the last changelog-backed version. Reset `package.json` to `1.2.9` to match `VERSION` / Sonar. The `1.4.0` package value is documented as **drift without tag/CHANGELOG section** and is discarded. Next cut is `1.3.0` (or patch) when cutting the first real release after this policy lands on `main`.

### Gates

- `scripts/version.sh check` — local SSOT alignment
- `scripts/check-semver-alignment.sh` — after the first `v*` tag exists, fail if releaseable commits appear on `main` without VERSION bump + CHANGELOG section (AIOS-adapted)
- CI: run `version.sh check` on PRs; run `check-semver-alignment.sh` on pushes/`main` (bootstrap-safe when no tags)

### Explicit non-goals

- Inventing historical tags for every past CHANGELOG entry
- Gitmoji requirement
- AIOS product release frequency

## Consequences

### Positive

- Predictable operator procedure
- Traceability: Issue → sandbox → main → tag → Release
- Aligns with Keep a Changelog + SemVer + GitHub Releases best practice

### Trade-offs

- First baseline tag is a deliberate follow-up after promote (policy before ceremony)
- Contributors must use `version.sh` instead of editing one file by hand

## Rejected alternatives

| Option | Reason |
|--------|--------|
| `package.json` as SSOT | Conflicts with HELP/`version.sh` and Sonar; Node is not the product runtime |
| Auto-tag inside every `version.sh bump` before merge | Tags would point at unmerged commits; tags only after `main` |
| Keep `check-version-alignment.sh` as pre-commit | Forces bump every commit |

## References

- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)
- AIOS `docs/guides/releases.md` / `scripts/check-semver-alignment.sh` (pattern reference)
- `docs/guides/releases.md`
- Issue #57
