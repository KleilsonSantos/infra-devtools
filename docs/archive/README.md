# Archived documentation

These files are **historical**. They describe the older “Protocolo Canônico 3→2→1 / OPÇÃO N” narrative.

## Current delivery SSOT (use these)

| Topic | Document |
|-------|----------|
| Branching | [ADR-0001](../adr/0001-sandbox-branching-strategy.md) |
| Releases / SemVer | [ADR-0002](../adr/0002-canonical-semver-releases.md) · [releases.md](../guides/releases.md) |
| Git / Issues / PRs | [git-workflow.md](../guides/git-workflow.md) |
| Delivery automation | [delivery-automation.md](../guides/delivery-automation.md) |
| Delivery verification | [delivery-verification.md](../guides/delivery-verification.md) |
| Branch protection | [BRANCH-PROTECTION-SETUP.md](../BRANCH-PROTECTION-SETUP.md) |
| Operator merge | `bash scripts/merge-pr.sh <PR>` |

## Why archived (#132)

CI and required checks use English names (`Protocol gate`, `Issue link`, `Version SSOT`, `PR base policy`). Keeping a second multi-thousand-line “Opção” protocol as live SSOT caused dual sources of truth and redundancy with the guides above.

Do not extend files in this folder. Prefer updating `docs/guides/` or ADRs.
