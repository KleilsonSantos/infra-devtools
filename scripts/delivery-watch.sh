#!/usr/bin/env bash
# Inventory open PRs and flag hygiene violations (ADR-0001).
# Intended for scheduled/manual Actions (delivery-watch) and local operators.
#
# Exit 1 if any open PR targets main with head ≠ sandbox (unless bypass label).
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

REPO="${GITHUB_REPOSITORY:-KleilsonSantos/infra-devtools}"
OUT_DIR="${DELIVERY_WATCH_OUT:-reports/delivery-watch}"
mkdir -p "$OUT_DIR"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
JSON_OUT="$OUT_DIR/open-prs-${STAMP}.json"
MD_OUT="$OUT_DIR/summary-${STAMP}.md"

: "${GH_TOKEN:=${GITHUB_TOKEN:-}}"

echo "delivery-watch: listing open PRs on ${REPO}"

gh api --paginate "repos/${REPO}/pulls?state=open&per_page=100" \
  --jq '[.[] | {
    number,
    title,
    base: .base.ref,
    head: .head.ref,
    author: .user.login,
    draft: .draft,
    mergeable: .mergeable,
    html_url: .html_url,
    labels: [.labels[].name]
  }]' > "$JSON_OUT"

python3 - "$JSON_OUT" "$MD_OUT" <<'PY'
import json, sys
path, md_path = sys.argv[1], sys.argv[2]
prs = json.load(open(path))
violations = []
for p in prs:
    labels = set(p.get("labels") or [])
    if p.get("base") == "main" and p.get("head") != "sandbox":
        if "ci:allow-main-base" in labels:
            continue
        violations.append(p)

lines = [
    "# Delivery watch — open PRs",
    "",
    f"Total open: **{len(prs)}**",
    f"Base-policy violations (main ← non-sandbox): **{len(violations)}**",
    "",
    "| # | Base | Head | Author | Title |",
    "|---|------|------|--------|-------|",
]
for p in sorted(prs, key=lambda x: x["number"], reverse=True):
    flag = " ⚠️" if p in violations else ""
    title = (p.get("title") or "").replace("|", "/")
    lines.append(
        f"| [{p['number']}]({p['html_url']}) | `{p['base']}` | `{p['head']}` | {p.get('author','')} | {title}{flag} |"
    )
lines.append("")
if violations:
    lines.append("## Violations (must retarget to sandbox or close)")
    lines.append("")
    for p in violations:
        lines.append(f"- #{p['number']}: `{p['head']}` → `main` ({p.get('author')})")
    lines.append("")
Path = __import__("pathlib").Path
Path(md_path).write_text("\n".join(lines) + "\n", encoding="utf-8")
print("\n".join(lines))
sys.exit(1 if violations else 0)
PY
