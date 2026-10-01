#!/usr/bin/env bash
# Merge PR with canonical subject (AIOS-adapted).
# Usage: bash scripts/merge-pr.sh <pr-number> [--delete-branch] [extra gh pr merge args]
#
# Never omit the subject — avoids GitHub default "Merge pull request #N from …"
# Prefer --merge (merge commit). Do not merge on red required checks.
#
# Refs: docs/guides/delivery-automation.md · AIOS scripts/merge-pr.sh
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: bash scripts/merge-pr.sh <pr-number> [extra gh pr merge args]" >&2
  exit 2
fi

PR="$1"
shift

if ! [[ "$PR" =~ ^[0-9]+$ ]]; then
  echo "Invalid PR number: $PR" >&2
  exit 2
fi

META=$(gh pr view "$PR" --json number,headRefName,baseRefName,state,title,statusCheckRollup)
STATE=$(printf '%s' "$META" | python3 -c 'import json,sys; print(json.load(sys.stdin)["state"])')
HEAD=$(printf '%s' "$META" | python3 -c 'import json,sys; print(json.load(sys.stdin)["headRefName"])')
BASE=$(printf '%s' "$META" | python3 -c 'import json,sys; print(json.load(sys.stdin)["baseRefName"])')

if [[ "$STATE" != "OPEN" ]]; then
  echo "PR #$PR is not OPEN (state=$STATE)" >&2
  exit 1
fi

# Soft warn on failing checks (branch protection may still block)
FAILS=$(printf '%s' "$META" | python3 -c '
import json,sys
d=json.load(sys.stdin)
fails=[]
for c in d.get("statusCheckRollup") or []:
    conc=c.get("conclusion")
    if conc in ("FAILURE","CANCELLED","TIMED_OUT","ACTION_REQUIRED"):
        fails.append(c.get("name") or "?")
print("\n".join(fails))
')
if [[ -n "$FAILS" ]]; then
  echo "merge-pr: FAIL — red checks on PR #$PR:" >&2
  printf '%s\n' "$FAILS" | sed 's/^/  - /' >&2
  echo "Fix CI first (AIOS: never merge on red)." >&2
  exit 1
fi

SUBJECT="merge: PR #${PR} — ${HEAD}"

echo "Merging PR #${PR} (${HEAD} → ${BASE})"
echo "Subject: ${SUBJECT}"

if gh pr merge --help 2>&1 | grep -q -- '--subject'; then
  gh pr merge "$PR" --merge --subject "$SUBJECT" "$@"
else
  gh pr merge "$PR" --merge -t "$SUBJECT" "$@"
fi

echo "OK: $SUBJECT"
