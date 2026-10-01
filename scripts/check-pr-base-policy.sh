#!/usr/bin/env bash
# Enforce ADR-0001: only promote PRs may target main (head must be sandbox).
# Work / bot PRs must target sandbox.
#
# Bypass label: ci:allow-main-base (emergencies only).
#
# Usage (CI): bash scripts/check-pr-base-policy.sh
# Local: PR_NUMBER=<n> bash scripts/check-pr-base-policy.sh
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

if [[ "${GITHUB_EVENT_NAME:-}" != "pull_request" && -z "${PR_NUMBER:-}" ]]; then
  echo "pr-base-policy: skip (not a pull_request event and PR_NUMBER unset)"
  exit 0
fi

if [[ -n "${GITHUB_EVENT_PATH:-}" && -f "${GITHUB_EVENT_PATH}" ]]; then
  BASE_REF="$(python3 -c "import json; print(json.load(open('${GITHUB_EVENT_PATH}'))['pull_request']['base']['ref'])")"
  HEAD_REF="$(python3 -c "import json; print(json.load(open('${GITHUB_EVENT_PATH}'))['pull_request']['head']['ref'])")"
  LABELS="$(python3 -c "import json; print(' '.join(l['name'] for l in json.load(open('${GITHUB_EVENT_PATH}'))['pull_request'].get('labels') or []))")"
  PR_NUMBER="$(python3 -c "import json; print(json.load(open('${GITHUB_EVENT_PATH}'))['pull_request']['number'])")"
else
  : "${PR_NUMBER:?PR_NUMBER required locally}"
  : "${GH_TOKEN:=${GITHUB_TOKEN:-}}"
  META="$(gh api "repos/${GITHUB_REPOSITORY:-KleilsonSantos/infra-devtools}/pulls/${PR_NUMBER}")"
  BASE_REF="$(printf '%s' "$META" | python3 -c "import json,sys; print(json.load(sys.stdin)['base']['ref'])")"
  HEAD_REF="$(printf '%s' "$META" | python3 -c "import json,sys; print(json.load(sys.stdin)['head']['ref'])")"
  LABELS="$(printf '%s' "$META" | python3 -c "import json,sys; print(' '.join(l['name'] for l in json.load(sys.stdin).get('labels') or []))")"
fi

echo "pr-base-policy: PR #${PR_NUMBER} ${HEAD_REF} → ${BASE_REF}"

if [[ " ${LABELS} " == *" ci:allow-main-base "* ]]; then
  echo "pr-base-policy: bypass label ci:allow-main-base — OK"
  exit 0
fi

if [[ "$BASE_REF" == "main" && "$HEAD_REF" != "sandbox" ]]; then
  echo "pr-base-policy: FAIL — PRs to main must come from head branch sandbox (promote only)." >&2
  echo "pr-base-policy: Retarget this PR to sandbox, or open a promote PR sandbox → main." >&2
  echo "pr-base-policy: Emergency bypass: label ci:allow-main-base" >&2
  exit 1
fi

echo "pr-base-policy: OK"
exit 0
