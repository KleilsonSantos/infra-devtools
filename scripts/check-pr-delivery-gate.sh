#!/usr/bin/env bash
# Local parity for CI delivery gates (especially issue-link) — run BEFORE push/PR.
# Adapted from AIOS scripts/check-pr-delivery-gate.sh (no product engines).
#
# Usage:
#   bash scripts/check-pr-delivery-gate.sh
#   PR_BASE=main bash scripts/check-pr-delivery-gate.sh
#   PR_NUMBER=91 bash scripts/check-pr-delivery-gate.sh
#   PR_BASE=sandbox PR_TITLE="ci: x" PR_BODY="Refs #91" PR_HEAD=ci/91-x bash scripts/check-pr-delivery-gate.sh
#
# CI SSOT: scripts/check-pr-issue-link.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$ROOT"

REPO="${GITHUB_REPOSITORY:-KleilsonSantos/infra-devtools}"
HEAD_REF="${PR_HEAD:-$(git branch --show-current)}"
BASE_REF="${PR_BASE:-sandbox}"

issue_nums_from_text() {
  python3 - <<'PY'
import os, re
text = os.environ.get("HAYSTACK", "")
nums = []
for m in re.finditer(
    r"(?i)\b(?:refs?|references?|related(?:\s+to)?|part\s+of|close[sd]?|fixe?[sd]?|resolve[sd]?)\b\s*:?\s*#(\d+)",
    text,
):
    nums.append(m.group(1))
for m in re.finditer(r"\(#(\d+)\)", text):
    nums.append(m.group(1))
for m in re.finditer(r"(?<![/\w])#(\d+)\b", text):
    nums.append(m.group(1))
seen = set()
for n in nums:
    if n not in seen:
        seen.add(n)
        print(n)
PY
}

verify_issue_exists() {
  local issue="$1"
  export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
  if [[ -z "${GH_TOKEN}" ]] || ! command -v gh >/dev/null 2>&1; then
    echo "delivery-gate: WARN — cannot verify Issue #${issue} (GH_TOKEN/gh missing); branch/text look OK"
    return 0
  fi
  local code
  code="$(gh api "repos/${REPO}/issues/${issue}" --jq 'if .pull_request then "pr" else "issue" end' 2>/dev/null || echo "missing")"
  if [[ "$code" == "issue" ]]; then
    echo "delivery-gate: OK — Issue #${issue} exists"
    return 0
  fi
  echo "delivery-gate: FAIL — #${issue} is not an Issue in ${REPO} (got: ${code})" >&2
  return 1
}

echo "delivery-gate: head=${HEAD_REF} base=${BASE_REF}"

if [[ -n "${PR_NUMBER:-}" ]]; then
  echo "delivery-gate: validating open PR #${PR_NUMBER} (CI issue-link parity)"
  PR_NUMBER="${PR_NUMBER}" bash "${SCRIPT_DIR}/check-pr-issue-link.sh"
  exit $?
fi

if [[ "$BASE_REF" == "main" ]]; then
  echo "delivery-gate: OK — PR → main (CI skips issue-link; use Closes/Fixes #N in PR body)"
  exit 0
fi

if [[ "$BASE_REF" == "sandbox" && "$HEAD_REF" == "main" ]]; then
  echo "delivery-gate: OK — main → sandbox sync (operational; issue-link skipped in CI)"
  exit 0
fi

# Bot heads never need an Issue
if [[ "$HEAD_REF" == dependabot/* || "$HEAD_REF" == snyk-* ]]; then
  echo "delivery-gate: OK — bot head ${HEAD_REF}"
  exit 0
fi

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  open_pr="$(gh pr list --repo "$REPO" --head "$HEAD_REF" --base "$BASE_REF" --state open --json number -q '.[0].number' 2>/dev/null || true)"
  if [[ -n "$open_pr" && "$open_pr" != "null" ]]; then
    echo "delivery-gate: validating open PR #${open_pr} (CI issue-link parity)"
    PR_NUMBER="${open_pr}" bash "${SCRIPT_DIR}/check-pr-issue-link.sh"
    exit $?
  fi
fi

if [[ "$HEAD_REF" =~ ^(feature|fix|docs|chore|ci|refactor|test|build|perf|security)/([0-9]+)- ]]; then
  verify_issue_exists "${BASH_REMATCH[2]}"
  exit $?
fi

if [[ -n "${PR_TITLE:-}" || -n "${PR_BODY:-}" ]]; then
  export HAYSTACK="${PR_TITLE:-}"$'\n'"${PR_BODY:-}"$'\n'"${HEAD_REF}"
  mapfile -t nums < <(issue_nums_from_text)
  if [[ ${#nums[@]} -gt 0 && -n "${nums[0]:-}" ]]; then
    verify_issue_exists "${nums[0]}"
    exit $?
  fi
fi

cat >&2 <<EOF
delivery-gate: FAIL — PR → sandbox would fail CI job issue-link.

Before push or gh pr create:
  1. Open a GitHub Issue with acceptance criteria
  2. Branch: <type>/<N>-slug (e.g. ci/91-aios-delivery-alignment)
  3. PR body/title: Refs #<N>

Validate draft PR text locally:
  PR_BASE=sandbox PR_HEAD=${HEAD_REF} \\
    PR_TITLE='ci(scope): summary (#N)' \\
    PR_BODY='Refs #N' \\
    bash scripts/check-pr-delivery-gate.sh

Operational sync PR (main → sandbox): PR_BASE=sandbox PR_HEAD=main bash scripts/check-pr-delivery-gate.sh

CI SSOT: bash scripts/check-pr-issue-link.sh
EOF
exit 1
