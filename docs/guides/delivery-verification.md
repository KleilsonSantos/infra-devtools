# Delivery verification checklist

Run this **at the end of every implementation** (before and after merge) so Issues and PRs stay correlated and nothing is left dangling.

## Purpose

Prove, with evidence:

```text
Issue → Branch → PR → CI → Review → Merge → Issue state
```

## Checklist

### 1. Issue

- [ ] Issue exists (template used when applicable)
- [ ] Acceptance criteria are clear
- [ ] Kickoff comment with branch name (recommended)

```bash
gh issue view <N> --json number,title,state,url
```

### 2. Pull Request(s)

| Stage | Base | Issue link | Command |
|-------|------|------------|---------|
| Work | `sandbox` | `Refs #<N>` | `gh pr view <P> --json baseRefName,body,url,state` |
| Promote | `main` | Prefer `Closes #<N>` | same |

- [ ] Work PR targets **`sandbox`**, not `main`
- [ ] CI green (including `issue-link` on work PRs)
- [ ] No “Made with Cursor” / IDE co-author trailers in commits or PR body

### 3. After merge to sandbox

- [ ] Work PR **MERGED**
- [ ] Issue still open if promote pending (or closed only if intentionally done on sandbox-only docs — prefer close on promote to `main`)
- [ ] Open promote PR `sandbox` → `main` when the slice is release-ready

```bash
gh pr list --base sandbox --state open
gh pr list --base main --head sandbox --state open
```

### 4. After promote to main

- [ ] Promote PR **MERGED**
- [ ] Linked Issue **CLOSED** (via `Closes #<N>` when appropriate)
- [ ] No orphan open Issues for the same gap without a follow-up Issue

```bash
gh issue view <N> --json state,closedAt,title
gh pr view <P> --json state,mergedAt,url
```

### 5. Portfolio snapshot (optional but recommended)

```bash
gh issue list --state open --limit 20
gh pr list --state open --limit 20
```

Record in the Issue comment or PR summary:

- Open Issues still relevant
- Open PRs (human vs Dependabot/Snyk)
- Next Issue ID for the following slice

## Definition of done (slice)

A delivery is **done** only when:

1. Acceptance criteria on the Issue are met, and
2. Code is on `main` (via promote), or an explicit follow-up Issue tracks remaining work, and
3. This checklist was executed (comment on the Issue with the command outputs or links).

## References

- [git-workflow.md](./git-workflow.md)
- [ADR-0001](../adr/0001-sandbox-branching-strategy.md)
