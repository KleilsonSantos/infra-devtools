# Releases and Tags (canonical)

SemVer `MAJOR.MINOR.PATCH` with **annotated** tags `vMAJOR.MINOR.PATCH`.  
Policy: [ADR-0002](../adr/0002-canonical-semver-releases.md) · Branching: [ADR-0001](../adr/0001-sandbox-branching-strategy.md).

## Policy

| Layer | Rule |
|-------|------|
| SSOT | `VERSION` — sync `package.json` + `sonar.projectVersion` |
| Every release | Bump via `scripts/version.sh`, CHANGELOG `## [X.Y.Z]`, annotated tag, GitHub Release |
| Where | **Only on `main`** after promote from `sandbox` |
| Gate | `scripts/check-semver-alignment.sh` — after first `v*` tag, releaseable commits on `main` require bump + CHANGELOG |
| Cadence | Aggregate slices; do not bump on every feature PR |

Non-releaseable alone (do not force bump): `chore`, `docs`, `ci`, `test`, `style`, `build`, `merge:`.

Releaseable (typically force bump before/at release): `feat`, `fix`, `perf`, `refactor` (and intentional `release`).

## Preconditions

1. Work merged to `sandbox` (Refs #N).
2. Promote PR `sandbox` → `main` merged (`Closes #N` when complete).
3. Working tree clean on up-to-date `main`.

## Procedure (canonical)

### 1. Align and choose bump

```bash
git checkout main && git pull origin main
bash scripts/version.sh show
bash scripts/version.sh check   # must pass
```

Decide: `patch` | `minor` | `major` from Conventional Commits since last tag (or since last CHANGELOG release if no tags yet).

### 2. Bump (does **not** push tags)

```bash
bash scripts/version.sh minor   # example → 1.3.0
# Edit CHANGELOG [Unreleased] / new section: move real notes; remove placeholders
git diff
git add VERSION package.json sonar-project.properties CHANGELOG.md
git commit -m "chore(release): bump to 1.3.0"
```

Open PR → `sandbox` then promote → `main` **or**, if already on a release branch from main with approval, merge the bump to `main` via the two-stage flow. Preferred: release bump as its own Issue + PR through sandbox.

### 3. Tag and GitHub Release (on `main` tip only)

```bash
git checkout main && git pull origin main
# confirm VERSION matches intended release
bash scripts/version.sh check

VERSION=$(tr -d '[:space:]' < VERSION)
git tag -a "v${VERSION}" -m "v${VERSION} — see CHANGELOG"
git push origin "v${VERSION}"

gh release create "v${VERSION}" \
  --title "v${VERSION}" \
  --notes "See CHANGELOG.md section [${VERSION}]."
```

### 4. Verify

```bash
bash scripts/check-semver-alignment.sh
gh release view "v${VERSION}"
git tag -l "v${VERSION}"
```

Complete [delivery-verification.md](./delivery-verification.md) including the release section.

## Bootstrap (no tags yet)

`check-semver-alignment.sh` exits 0 with message `nenhuma tag v* — skip (bootstrap)`.

First baseline after this policy is on `main`:

1. Ensure SSOT aligned (ADR-0002 skew resolution → `1.2.9` until next bump).
2. Cut `1.3.0` (or patch) with real CHANGELOG notes for sandbox/CI/delivery work.
3. Create `v1.3.0` + GitHub Release.

Do **not** invent tags for every historical CHANGELOG row unless explicitly decided later.

## Local / CI commands

```bash
bash scripts/version.sh show|check|patch|minor|major
bash scripts/check-semver-alignment.sh
```

Deprecated: `scripts/check-version-alignment.sh` (legacy; do not use in hooks/CI).

## Related

- [git-workflow.md](./git-workflow.md)
- [delivery-verification.md](./delivery-verification.md)
- `scripts/version.sh`
- AIOS pattern reference: `docs/guides/releases.md` (adapted)
