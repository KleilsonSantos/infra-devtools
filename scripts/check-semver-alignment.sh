#!/usr/bin/env bash
# SemVer anti-drift gate (ADR-0002 / #57).
# Adapted from AIOS scripts/check-semver-alignment.sh for infra-devtools.
#
# SSOT = VERSION (must match package.json and, when present, CHANGELOG section).
# Fails if main has releaseable commits after the last tag v* without a VERSION bump
# greater than the tag and a ## [X.Y.Z] CHANGELOG section.
#
# Usage:
#   bash scripts/check-semver-alignment.sh
#   bash scripts/check-semver-alignment.sh origin/main HEAD
set -euo pipefail

BASE_REF="${1:-}"
HEAD_REF="${2:-HEAD}"

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

if [[ ! -f VERSION ]]; then
  echo "semver-align: VERSION ausente — FAIL" >&2
  exit 1
fi

SSOT_VERSION="$(tr -d '[:space:]' < VERSION)"

if [[ -f package.json ]]; then
  PKG_VERSION="$(python3 -c "import json; print(json.load(open('package.json'))['version'])")"
  if [[ "$PKG_VERSION" != "$SSOT_VERSION" ]]; then
    echo "semver-align: FAIL — package.json ($PKG_VERSION) != VERSION ($SSOT_VERSION)" >&2
    exit 1
  fi
fi

if [[ -f sonar-project.properties ]]; then
  SONAR_VERSION="$(grep -E '^sonar.projectVersion=' sonar-project.properties | cut -d= -f2 | tr -d '[:space:]')"
  if [[ -n "$SONAR_VERSION" && "$SONAR_VERSION" != "$SSOT_VERSION" ]]; then
    echo "semver-align: FAIL — sonar.projectVersion ($SONAR_VERSION) != VERSION ($SSOT_VERSION)" >&2
    exit 1
  fi
fi

LAST_TAG="$(git tag -l 'v*.*.*' --sort=-v:refname | head -n 1 || true)"
if [[ -z "$LAST_TAG" ]]; then
  echo "semver-align: nenhuma tag v* — skip (bootstrap); VERSION=$SSOT_VERSION alinhado aos arquivos"
  exit 0
fi

TAG_VERSION="${LAST_TAG#v}"
echo "semver-align: VERSION=$SSOT_VERSION  last_tag=$LAST_TAG"

version_gt() {
  python3 - "$1" "$2" <<'PY'
import sys
def parse(v):
    return tuple(int(x) for x in v.split(".")[:3])
a, b = parse(sys.argv[1]), parse(sys.argv[2])
sys.exit(0 if a > b else 1)
PY
}

version_eq() {
  [[ "$1" == "$2" ]]
}

if [[ -n "$BASE_REF" ]]; then
  RANGE="${LAST_TAG}..${HEAD_REF}"
else
  RANGE="${LAST_TAG}..${HEAD_REF}"
fi

if ! git rev-parse --verify "$LAST_TAG" >/dev/null 2>&1; then
  echo "semver-align: tag $LAST_TAG inválida" >&2
  exit 1
fi

SUBJECTS=()
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  SUBJECTS+=("$line")
done < <(git log --format='%s' "$RANGE" 2>/dev/null || true)

if [[ ${#SUBJECTS[@]} -eq 0 ]]; then
  echo "semver-align: nenhum commit após $LAST_TAG — OK"
  exit 0
fi

RELEASEABLE=0
for subject in "${SUBJECTS[@]}"; do
  if [[ "$subject" =~ ^[Mm]erge[[:space:]] ]] || [[ "$subject" =~ ^merge: ]]; then
    continue
  fi
  if [[ "$subject" =~ ^(chore|docs|ci|test|style|build)(\(.+\))?:[[:space:]] ]]; then
    continue
  fi
  if [[ "$subject" =~ ^(feat|fix|perf|refactor|release)(\(.+\))?:[[:space:]] ]]; then
    RELEASEABLE=1
    echo "semver-align: releaseable → $subject"
  fi
done

if [[ "$RELEASEABLE" -eq 0 ]]; then
  echo "semver-align: só commits não-releaseable após $LAST_TAG — OK"
  exit 0
fi

if version_eq "$SSOT_VERSION" "$TAG_VERSION"; then
  echo "semver-align: FAIL — há mudanças releaseable após $LAST_TAG," >&2
  echo "  mas VERSION ainda está em $SSOT_VERSION." >&2
  echo "  Faça bump (scripts/version.sh) + CHANGELOG [X.Y.Z], merge em main, depois tag." >&2
  echo "  Ver docs/guides/releases.md e ADR-0002." >&2
  exit 1
fi

if ! version_gt "$SSOT_VERSION" "$TAG_VERSION"; then
  echo "semver-align: FAIL — VERSION ($SSOT_VERSION) não é > $TAG_VERSION" >&2
  exit 1
fi

if ! grep -qE "^## \[${SSOT_VERSION}\]" CHANGELOG.md; then
  echo "semver-align: FAIL — CHANGELOG sem seção ## [${SSOT_VERSION}]" >&2
  exit 1
fi

echo "semver-align: OK — $SSOT_VERSION > $TAG_VERSION e CHANGELOG alinhado"
exit 0
