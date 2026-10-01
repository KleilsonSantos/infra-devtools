## Summary

<!-- What changed and why -->

## Issue

- Refs #<N> <!-- required for PRs → sandbox (CI job `issue-link`, ADR-0001 / #55) -->

<!-- On promote sandbox → main, prefer: Closes #<N>
     (GitHub closing keywords only apply on the default branch). -->

## Change type

- [ ] feat
- [ ] fix
- [ ] docs
- [ ] refactor
- [ ] ci
- [ ] chore
- [ ] test
- [ ] security

## Checklist

- [ ] GitHub **Issue** opened (or reused) before this branch
- [ ] Branch created from up-to-date **`sandbox`**
- [ ] Target: work branch → `sandbox`; later promote `sandbox` → `main`
- [ ] Local validation for the touched area (make/npm/pytest/scripts as applicable)
- [ ] Docs / ADR updated if architecture or operator workflow changed
- [ ] No secrets committed (`.env` stays local)
- [ ] Ran [delivery-verification](../docs/guides/delivery-verification.md) checklist before merge

## Test plan

<!-- How reviewers can validate -->
