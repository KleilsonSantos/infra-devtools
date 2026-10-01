# ADR-0001: Branch strategy with sandbox integration

- **Status:** Accepted
- **Date:** 2026-09-30
- **Deciders:** Kleilson dos Santos

## Context

`infra-devtools` historically used a **main-only** PR model with Canonical protocol 3→2→1. After the engineering audit and alignment with [AI Operating System](https://github.com/KleilsonSantos/ai-operating-system) delivery practices, the project needs a safer integration branch before production merges, without copying AIOS product architecture.

Closing keywords (`Closes` / `Fixes` / `Resolves`) only auto-link and close Issues when the PR targets the **default branch** ([GitHub docs](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue)). An integration branch therefore needs an explicit Issue reference gate (`Refs #N`).

## Decision

```text
feature/* | fix/* | docs/* | chore/* | ci/* | …
              │
              ▼  PR #1 (Refs #N) — CI + issue-link
           sandbox          ← continuous integration
              │
              ▼  PR #2 (prefer Closes #N) — promote
            main            ← production / tagged releases
```

### Rules

1. No direct commits to `main` or `sandbox` after this ADR.
2. Two PRs per delivery: work branch → `sandbox`, then `sandbox` → `main`.
3. Commits: [Conventional Commits](https://www.conventionalcommits.org/) (gitmoji optional; not required in this repo).
4. Work PRs → `sandbox` **must** reference a real GitHub Issue (`Refs #N` / `#N`). Enforced by `scripts/check-pr-issue-link.sh` (CI job `issue-link`).
5. Promote PRs → `main` should use `Closes #N` / `Fixes #N` when the Issue is complete. The issue-link job **skips** when base is `main` (promote path).
6. Bypass (rare): label `ci:no-issue-required`. Dependabot/Snyk actors are skipped.
7. Releases: SemVer via `VERSION` / tags when cutting a release (see CHANGELOG). Keep a single source of truth — version skew is tracked separately.

### Bootstrap exception

Creating the permanent `sandbox` branch from `main` (2026-09-30) and the first documentation/CI PR that establishes this model are the documented bootstrap.

## Consequences

### Positive

- Integration risk lands on `sandbox` before `main`
- Issue → PR traceability matches GitHub semantics and AIOS delivery reference
- Canonical 3→2→1 remains valid on each PR stage

### Trade-offs

- Two merges per delivery (extra promote PR)
- Branch protection must be configured for **both** `main` and `sandbox` in GitHub Settings (see `docs/BRANCH-PROTECTION-SETUP.md`)

## Rejected alternatives

| Option | Reason |
|--------|--------|
| Keep main-only | Higher blast radius; misaligned with portfolio delivery standard |
| Embed AIOS engines into this repo | Out of scope; AIOS ADR-0001 rejects embedding the platform |

## References

- AIOS ADR-0002 (branching reference; adapted, not copied wholesale)
- `docs/guides/git-workflow.md`
- `docs/guides/delivery-verification.md`
- Issue #55
