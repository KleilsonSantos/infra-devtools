#!/usr/bin/env bash
# Inventory open PRs: base-policy (ADR-0001) + failing check runs.
# Intended for scheduled/manual Actions (delivery-watch) and local operators.
#
# This is NOT a second CI. It must not redden healthy PRs because of other PRs.
#
# Exit 1 only when HARD_FAIL=1 (default on schedule / workflow_dispatch) AND
# there is at least one base-policy violation (main ← head≠sandbox without
# ci:allow-main-base). Draft PRs still count for base-policy.
#
# Check-run failures are always reported in the summary/artifact but never
# cause exit 1 (avoids self-contagion via "Open PR hygiene inventory").
#
# On pull_request / workflow_run / local default: HARD_FAIL=0 (report only).
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

REPO="${GITHUB_REPOSITORY:-KleilsonSantos/infra-devtools}"
OUT_DIR="${DELIVERY_WATCH_OUT:-reports/delivery-watch}"
mkdir -p "$OUT_DIR"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
JSON_OUT="$OUT_DIR/open-prs-${STAMP}.json"
MD_OUT="$OUT_DIR/summary-${STAMP}.md"

# Own check name — never treat as a PR CI failure (breaks feedback loops).
SELF_CHECK_NAME="${DELIVERY_WATCH_CHECK_NAME:-Open PR hygiene inventory}"

HARD_FAIL="${HARD_FAIL:-}"
if [[ -z "$HARD_FAIL" ]]; then
  case "${GITHUB_EVENT_NAME:-}" in
    schedule|workflow_dispatch) HARD_FAIL=1 ;;
    *) HARD_FAIL=0 ;;
  esac
fi

: "${GH_TOKEN:=${GITHUB_TOKEN:-}}"

echo "delivery-watch: listing open PRs on ${REPO} (HARD_FAIL=${HARD_FAIL})"

gh api --paginate "repos/${REPO}/pulls?state=open&per_page=100" \
  --jq '[.[] | {
    number,
    title,
    base: .base.ref,
    head: .head.ref,
    head_sha: .head.sha,
    author: .user.login,
    draft: .draft,
    mergeable: .mergeable,
    html_url: .html_url,
    labels: [.labels[].name]
  }]' > "$JSON_OUT"

# Enrich with check-run conclusions per head SHA
python3 - "$JSON_OUT" "$REPO" "$SELF_CHECK_NAME" <<'PY'
import json, os, subprocess, sys

path, repo, self_name = sys.argv[1], sys.argv[2], sys.argv[3]
prs = json.load(open(path))

def gh_api(url: str):
    env = os.environ.copy()
    cmd = ["gh", "api", url]
    out = subprocess.check_output(cmd, env=env, text=True)
    return json.loads(out)

for p in prs:
    sha = p.get("head_sha") or ""
    fails = []
    pending = []
    if not sha:
        p["check_failures"] = []
        p["check_pending"] = []
        continue
    try:
        data = gh_api(f"repos/{repo}/commits/{sha}/check-runs?per_page=100")
        runs = data.get("check_runs") or []
    except Exception as e:
        p["check_failures"] = [f"api-error:{e}"]
        p["check_pending"] = []
        continue
    # Dedupe by name keeping latest started_at
    latest = {}
    for r in runs:
        name = r.get("name") or "unknown"
        prev = latest.get(name)
        if prev is None or (r.get("started_at") or "") > (prev.get("started_at") or ""):
            latest[name] = r
    for name, r in latest.items():
        if name == self_name:
            continue
        status = r.get("status")
        conclusion = r.get("conclusion")
        if status != "completed":
            pending.append(name)
            continue
        if conclusion in ("failure", "cancelled", "timed_out", "action_required"):
            fails.append(f"{name}:{conclusion}")
    p["check_failures"] = fails
    p["check_pending"] = pending

json.dump(prs, open(path, "w"), indent=2)
print(f"delivery-watch: enriched {len(prs)} PR(s) with check runs")
PY

python3 - "$JSON_OUT" "$MD_OUT" "$HARD_FAIL" <<'PY'
import json, sys
from pathlib import Path

path, md_path, hard_fail = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
prs = json.load(open(path))
base_violations = []
ci_failures = []
for p in prs:
    labels = set(p.get("labels") or [])
    if p.get("base") == "main" and p.get("head") != "sandbox":
        if "ci:allow-main-base" not in labels:
            base_violations.append(p)
    fails = p.get("check_failures") or []
    if fails:
        ci_failures.append(p)

lines = [
    "# Delivery watch — open PRs",
    "",
    f"Total open: **{len(prs)}**",
    f"Base-policy violations (main ← non-sandbox): **{len(base_violations)}**",
    f"PRs with failing checks (reported only): **{len(ci_failures)}**",
    f"Hard-fail on base-policy: **{hard_fail}**",
    "",
    "| # | Base | Head | Author | Checks | Title |",
    "|---|------|------|--------|--------|-------|",
]
for p in sorted(prs, key=lambda x: x["number"], reverse=True):
    flags = []
    if p in base_violations:
        flags.append("base⚠️")
    fails = p.get("check_failures") or []
    if fails:
        flags.append("ci❌")
    pending = p.get("check_pending") or []
    if pending and not fails:
        flags.append("ci…")
    flag = (" " + " ".join(flags)) if flags else ""
    title = (p.get("title") or "").replace("|", "/")
    check_cell = ", ".join(fails[:3]) if fails else ("pending" if pending else "ok")
    if len(fails) > 3:
        check_cell += f" (+{len(fails)-3})"
    lines.append(
        f"| [{p['number']}]({p['html_url']}) | `{p['base']}` | `{p['head']}` | {p.get('author','')} | {check_cell}{flag} | {title} |"
    )
lines.append("")

if base_violations:
    lines.append("## Base-policy violations (retarget to sandbox or close)")
    lines.append("")
    for p in base_violations:
        lines.append(f"- #{p['number']}: `{p['head']}` → `main` ({p.get('author')})")
    lines.append("")

if ci_failures:
    lines.append("## Failing checks (report only — not a merge gate)")
    lines.append("")
    for p in ci_failures:
        lines.append(f"- #{p['number']}: {', '.join(p.get('check_failures') or [])}")
    lines.append("")

if not hard_fail:
    lines.append("_Event mode: report only (`HARD_FAIL=0`). Schedule/dispatch hard-fails on base-policy._")
    lines.append("")

Path(md_path).write_text("\n".join(lines) + "\n", encoding="utf-8")
print("\n".join(lines))
sys.exit(1 if (hard_fail and base_violations) else 0)
PY
