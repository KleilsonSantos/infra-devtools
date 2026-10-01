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

```bash
# when a PR already exists:
PR_NUMBER=<n> bash scripts/check-pr-delivery-gate.sh   # if present
# or:
PR_NUMBER=<n> bash scripts/check-pr-issue-link.sh
```

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
- [delivery-verification.md](./delivery-verification.md) — checklist after each delivery
- [BRANCH-PROTECTION-SETUP.md](../BRANCH-PROTECTION-SETUP.md)
- [CONTRIBUTING.md](../../CONTRIBUTING.md)
