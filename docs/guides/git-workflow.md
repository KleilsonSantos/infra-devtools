# Git workflow — branches, Issues, and PRs

Official delivery flow for `infra-devtools` after [ADR-0001](../adr/0001-sandbox-branching-strategy.md).

## Overview

```text
Issue (#N)
   │
   ▼
feature/* | fix/* | docs/* | chore/* | ci/*
   │
   ▼  PR #1 — Refs #N
sandbox
   │
   ▼  PR #2 — prefer Closes #N
main
```

| Branch | Role |
|--------|------|
| `sandbox` | Integration + CI |
| `main` | Production / releases |

## Kickoff

```bash
git checkout sandbox && git pull origin sandbox
git checkout -b <type>/<N>-<slug>   # prefer issue id in branch name
gh issue comment <N> --body "Kickoff: branch \`<type>/<N>-<slug>\` from sandbox."
```

**Before push / `gh pr create`:**

```bash
bash scripts/check-pr-delivery-gate.sh
# or with draft text:
PR_BASE=sandbox PR_HEAD="$(git branch --show-current)" \
  PR_TITLE='fix(scope): summary (#N)' PR_BODY='Refs #N' \
  bash scripts/check-pr-delivery-gate.sh
```

PR → `sandbox` body **must** include `Refs #<N>` (or `#<N>`). CI job `issue-link` fails otherwise.

On promote `sandbox` → `main`, prefer `Closes #<N>` ([GitHub linking docs](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue) — closing keywords apply on the default branch).

## Local parity before push

Enable hooks once (also runs on `npm install` via `prepare`):

```bash
git config core.hooksPath .githooks
# or: npm run prepare
```

| Hook | Role |
|------|------|
| `pre-commit` | Fast: `bash -n` on staged `.sh`, flake8 on staged `src/**/*.py`, optional `ggshield` |
| `pre-push` | Blocks direct push to `main`/`sandbox`; runs `scripts/preflight.sh` |

```bash
bash scripts/preflight.sh   # VERSION SSOT, SemVer, unit tests, bandit, yamllint, shell -n
npm run preflight           # same
bash scripts/check-pr-delivery-gate.sh   # issue-link parity (AIOS-adapted)
```

When a PR already exists:

```bash
PR_NUMBER=<n> bash scripts/check-pr-issue-link.sh
```

Hooks are early feedback; GitHub Actions remain the enforcement layer. Prefer not to use `--no-verify`.

## Merges (required)

```bash
bash scripts/merge-pr.sh <n>
# equivalent:
gh pr merge <n> --merge --subject "merge: PR #<n> — <branch>"
```

- **Never merge on red** required checks (`merge-pr.sh` refuses).
- Prefer `--merge` (merge commit). Avoid ad-hoc squash that hides history unless intentional.
- Babysit CI async: open PR → continue work → `gh pr checks <n>` when settled ([delivery-automation.md](./delivery-automation.md)).

## Dependabot

Configured in [`.github/dependabot.yml`](../../.github/dependabot.yml) (AIOS-aligned).

| Kind | Target | Notes |
|------|--------|-------|
| **Version updates** (scheduled) | `sandbox` | Review → merge → promote |
| **Security updates** | default branch (`main`) when `target-branch` is set | GitHub limitation — prefer Dependabot **alerts** + manual/sandbox bumps; do not leave large queues on `main` |
| **Dependabot alerts** | Security tab | Keep enabled |

Close stale version-update PRs that still target `main` so Dependabot recreates them against `sandbox`.

`issue-link` skips Dependabot (`dependabot[bot]` via string equality — never unquoted `case`).

## What not to do

- Commit directly on `main` / `sandbox`
- Open work PRs straight to `main` (except documented emergencies)
- Skip Issue creation for human-driven work
- Invent parallel “watchers” that block every PR because *other* PRs are red — use the delivery map + babysit
- Merge with GitHub’s default subject / merge on red

## Related

- [delivery-automation.md](./delivery-automation.md) — event → next action (SSOT for agents)
- [ADR-0001](../adr/0001-sandbox-branching-strategy.md)
- [ADR-0002](../adr/0002-canonical-semver-releases.md) · [releases.md](./releases.md)
- [delivery-verification.md](./delivery-verification.md) — checklist after each delivery
- [BRANCH-PROTECTION-SETUP.md](../BRANCH-PROTECTION-SETUP.md)
- [CONTRIBUTING.md](../../CONTRIBUTING.md)
- AIOS reference: [git-workflow.md](https://github.com/KleilsonSantos/ai-operating-system/blob/main/docs/guides/git-workflow.md)
