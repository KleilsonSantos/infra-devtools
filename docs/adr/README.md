# Architecture Decision Records

ADRs record **accepted** architectural / delivery decisions for `infra-devtools`.

| ADR | Title | Status |
|-----|-------|--------|
| [0001](./0001-sandbox-branching-strategy.md) | Branch strategy with sandbox integration | Accepted |

## When to write an ADR

- Branching / release model changes
- Observability stack choice (e.g. ELK vs Loki/Tempo)
- Security boundaries that constrain operators or CI
- Any decision that would be costly to reverse silently

Code and Compose remain the runtime source of truth; ADRs explain **why**.

## Format

Use the existing ADR-0001 structure (Context → Decision → Consequences → Rejected alternatives → References).
