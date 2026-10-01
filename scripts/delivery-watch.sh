#!/usr/bin/env bash
# Inventory open PRs: base-policy (ADR-0001) + failing check runs.
# Intended for scheduled/manual Actions (delivery-watch) and local operators.
#
# Exit 1 if:
#   - any open PR targets main with head ≠ sandbox (unless ci:allow-main-base), OR
#   - any open PR has a completed check run with conclusion failure/cancelled
#     (pending/neutral/skipped ignored; draft PRs still reported but do not fail CI unless POLICY_FAIL_DRAFTS=1)
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

REPO="${GITHUB_REPOSITORY:-KleilsonSantos/infra-devtools}"
OUT_DIR="${DELIVERY_WATCH_OUT:-reports/delivery-watch}"
mkdir -p "$OUT_DIR"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
JSON_OUT="$OUT_DIR/open-prs-${STAMP}.json"
MD_OUT="$OUT_DIR/summary-${STAMP}.md"
FAIL_DRAFTS="${POLICY_FAIL_DRAFTS:-0}"

: "${GH_TOKEN:=${GITHUB_TOKEN:-}}"

echo "delivery-watch: listing open PRs on ${REPO}"

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
python3 - "$JSON_OUT" "$REPO" <<'PY'
import json, os, subprocess, sys

path, repo = sys.argv[1], sys.argv[2]
token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN") or ""
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

python3 - "$JSON_OUT" "$MD_OUT" "$FAIL_DRAFTS" <<'PY'
import json, sys
from pathlib import Path

path, md_path, fail_drafts = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
prs = json.load(open(path))
base_violations = []
ci_failures = []
for p in prs:
    labels = set(p.get("labels") or [])
    draft = bool(p.get("draft"))
    if p.get("base") == "main" and p.get("head") != "sandbox":
        if "ci:allow-main-base" not in labels:
            base_violations.append(p)
    fails = p.get("check_failures") or []
    if fails and (not draft or fail_drafts):
        ci_failures.append(p)

lines = [
    "# Delivery watch — open PRs",
    "",
    f"Total open: **{len(prs)}**",
    f"Base-policy violations (main ← non-sandbox): **{len(base_violations)}**",
    f"PRs with failing checks: **{len(ci_failures)}**",
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
    lines.append("## Failing checks (investigate / fix / close)")
    lines.append("")
    for p in ci_failures:
        lines.append(f"- #{p['number']}: {', '.join(p.get('check_failures') or [])}")
    lines.append("")

Path(md_path).write_text("\n".join(lines) + "\n", encoding="utf-8")
print("\n".join(lines))
sys.exit(1 if (base_violations or ci_failures) else 0)
PY
