#!/usr/bin/env bash
# Require a GitHub Issue reference on PRs targeting main (main-only branch model).
#
# Adapted from AIOS scripts/check-pr-issue-link.sh for infra-devtools until/unless
# a sandbox promotion flow is adopted. Closing keywords auto-link on the default
# branch per GitHub docs:
# https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue
#
# Usage (CI):
#   bash scripts/check-pr-issue-link.sh
#
# Local:
#   PR_NUMBER=<n> GH_TOKEN=... bash scripts/check-pr-issue-link.sh
#
# Bypass:
#   - dependabot[bot], dependabot, snyk[bot]
#   - Label `ci:no-issue-required`
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

DEFAULT_BASE_REF="${ISSUE_LINK_BASE_REF:-main}"

if [[ "${GITHUB_EVENT_NAME:-}" != "pull_request" && -z "${PR_NUMBER:-}" ]]; then
  echo "issue-link: skip (not a pull_request event and PR_NUMBER unset)"
  exit 0
fi

if [[ -n "${GITHUB_EVENT_PATH:-}" && -f "${GITHUB_EVENT_PATH}" ]]; then
  BASE_REF="$(python3 -c "import json; print(json.load(open('${GITHUB_EVENT_PATH}'))['pull_request']['base']['ref'])")"
  HEAD_REF="$(python3 -c "import json; print(json.load(open('${GITHUB_EVENT_PATH}'))['pull_request']['head']['ref'])")"
  PR_TITLE="$(python3 -c "import json; print(json.load(open('${GITHUB_EVENT_PATH}'))['pull_request'].get('title') or '')")"
  PR_BODY="$(python3 -c "import json; print(json.load(open('${GITHUB_EVENT_PATH}'))['pull_request'].get('body') or '')")"
  PR_NUMBER="$(python3 -c "import json; print(json.load(open('${GITHUB_EVENT_PATH}'))['pull_request']['number'])")"
  ACTOR="$(python3 -c "import json; print(json.load(open('${GITHUB_EVENT_PATH}')).get('sender',{}).get('login') or '')")"
  LABELS="$(python3 -c "import json; print(' '.join(l['name'] for l in json.load(open('${GITHUB_EVENT_PATH}'))['pull_request'].get('labels') or []))")"
else
  : "${PR_NUMBER:?PR_NUMBER required when GITHUB_EVENT_PATH is unset}"
  export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
  if [[ -z "${GH_TOKEN}" ]]; then
    echo "issue-link: FAIL — GH_TOKEN/GITHUB_TOKEN required" >&2
    exit 1
  fi
  REPO_FALLBACK="KleilsonSantos/infra-devtools"
  PR_JSON="$(gh api "repos/${GITHUB_REPOSITORY:-${REPO_FALLBACK}}/pulls/${PR_NUMBER}")"
  BASE_REF="$(printf '%s' "$PR_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['base']['ref'])")"
  HEAD_REF="$(printf '%s' "$PR_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['head']['ref'])")"
  PR_TITLE="$(printf '%s' "$PR_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin).get('title') or '')")"
  PR_BODY="$(printf '%s' "$PR_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin).get('body') or '')")"
  ACTOR="$(printf '%s' "$PR_JSON" | python3 -c "import json,sys; print((json.load(sys.stdin).get('user') or {}).get('login') or '')")"
  LABELS="$(printf '%s' "$PR_JSON" | python3 -c "import json,sys; print(' '.join(l['name'] for l in json.load(sys.stdin).get('labels') or []))")"
fi

echo "issue-link: PR #${PR_NUMBER} ${HEAD_REF} → ${BASE_REF} (actor=${ACTOR})"

if [[ "$BASE_REF" != "$DEFAULT_BASE_REF" ]]; then
  echo "issue-link: skip (base is '${BASE_REF}', expected '${DEFAULT_BASE_REF}')"
  exit 0
fi

case "$ACTOR" in
  dependabot[bot]|dependabot|snyk[bot]|snyk)
    echo "issue-link: skip (bot actor: ${ACTOR})"
    exit 0
    ;;
esac

if [[ " $LABELS " == *" ci:no-issue-required "* ]]; then
  echo "issue-link: skip (label ci:no-issue-required)"
  exit 0
fi

HAYSTACK="${PR_TITLE}"$'\n'"${PR_BODY}"$'\n'"${HEAD_REF}"
export HAYSTACK

ISSUE_NUMS=()
while IFS= read -r n; do
  [[ -n "$n" ]] && ISSUE_NUMS+=("$n")
done < <(
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
for m in re.finditer(r"(?<![A-Za-z0-9_/#])#(\d+)\b", text):
    nums.append(m.group(1))
for m in re.finditer(r"(?i)(?:^|/)(?:issue-)?(\d{1,6})(?:[-_/]|$)", text):
    nums.append(m.group(1))
seen = []
for n in nums:
    if n not in seen:
        seen.append(n)
print("\n".join(seen))
PY
)

if [[ ${#ISSUE_NUMS[@]} -eq 0 ]]; then
  echo "issue-link: FAIL — no GitHub issue reference found in PR title/body/branch." >&2
  echo "  Open an Issue first, then add e.g.:" >&2
  echo "    Refs #53" >&2
  echo "    Closes #53" >&2
  echo "  Bypass (rare): label ci:no-issue-required" >&2
  exit 1
fi

export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
if [[ -z "${GH_TOKEN}" ]]; then
  echo "issue-link: FAIL — GITHUB_TOKEN required to verify issue exists" >&2
  exit 1
fi

REPO="${GITHUB_REPOSITORY:-KleilsonSantos/infra-devtools}"
VALID=""
for n in "${ISSUE_NUMS[@]}"; do
  [[ -z "$n" ]] && continue
  if [[ "$n" == "$PR_NUMBER" ]]; then
    echo "issue-link: ignore self-ref #$n (this PR)"
    continue
  fi
  CODE="$(gh api -X GET "repos/${REPO}/issues/${n}" --jq 'if .pull_request then "pr" else "issue" end' 2>/dev/null || echo "missing")"
  if [[ "$CODE" == "issue" ]]; then
    VALID="$n"
    break
  fi
  echo "issue-link: #$n is ${CODE} (need a real Issue)"
done

if [[ -z "$VALID" ]]; then
  echo "issue-link: FAIL — references found (${ISSUE_NUMS[*]}) but none resolve to an Issue in ${REPO}." >&2
  exit 1
fi

echo "issue-link: OK — linked Issue #${VALID}"
exit 0
