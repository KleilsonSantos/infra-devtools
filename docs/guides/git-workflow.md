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
git checkout -b <type>/<slug>
# optional: comment on the Issue with the branch name
gh issue comment <N> --body "Kickoff: branch \`<type>/<slug>\` from sandbox."
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
```

When a PR already exists, issue-link can be checked with:

```bash
PR_NUMBER=<n> bash scripts/check-pr-issue-link.sh
```

Hooks are early feedback; GitHub Actions remain the enforcement layer. Prefer not to use `--no-verify`.

## Merges

Prefer:

```bash
bash scripts/merge-pr.sh <n>
# or:
gh pr merge <n> --merge --subject "merge: PR #<n> — <branch>"
```

Avoid GitHub’s default merge subject when using the project script conventions.

## What not to do

- Commit directly on `main` / `sandbox`
- Open work PRs straight to `main` (except documented emergencies)
- Skip Issue creation for human-driven work

## Related

- [ADR-0001](../adr/0001-sandbox-branching-strategy.md)
- [ADR-0002](../adr/0002-canonical-semver-releases.md) · [releases.md](./releases.md)
- [delivery-verification.md](./delivery-verification.md) — checklist after each delivery
- [BRANCH-PROTECTION-SETUP.md](../BRANCH-PROTECTION-SETUP.md)
- [CONTRIBUTING.md](../../CONTRIBUTING.md)
