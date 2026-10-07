#!/usr/bin/env bash
################################################################################
# e2e-adherence-evidence.sh — Prova auditável por serviço (comando + stdout)
#
# Roda cada checagem funcional no stack JÁ UP, grava:
#   - evidence/<svc>/<step>.{cmd,out,rc}
#   - EVIDENCE.md  (humano, linha a linha)
#   - evidence.json (máquina)
#
# Usage:
#   bash scripts/e2e-adherence-evidence.sh
#   E2E_OUT=reports/e2e-evidence/manual bash scripts/e2e-adherence-evidence.sh
################################################################################
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

ENV_FILE="${ENV_FILE:-.env}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
TOKEN="$(date -u +%Y%m%d%H%M%S)-$$"
OUT_DIR="${E2E_OUT:-reports/e2e-evidence/${STAMP}}"
EV_DIR="$OUT_DIR/evidence"
mkdir -p "$EV_DIR"

[[ -f "$ENV_FILE" ]] && set -a && . "$ENV_FILE" && set +a

compose() { docker compose --env-file "$ENV_FILE" "$@"; }

PASS=0
FAIL=0
SKIP=0
declare -a ROWS=()

redact() {
  # strip passwords from recorded command lines (keep keys)
  sed -E \
    -e 's/(-p|--password)[[:space:]]+[^[:space:]]+/\1 ***/g' \
    -e 's/(MYSQL_PWD=)[^[:space:]]+/\1***/g' \
    -e 's#(-u[[:space:]]*)([^:/\"]+):([^@/\"]+)#\1\2:***#g' \
    -e 's#(//)([^:/@]+):([^@/]+)@#\1\2:***@#g'
}

record() {
  local svc="$1" step="$2" verdict="$3" seconds="$4" cmd="$5" outfile="$6"
  local out preview
  out="$(cat "$outfile" 2>/dev/null || true)"
  # avoid SIGPIPE/pipefail on large outs (head closes early)
  set +o pipefail
  preview="$(printf '%s' "$out" | head -c 1200 || true)"
  set -o pipefail
  ROWS+=("$svc|$step|$verdict|$seconds|$cmd|$outfile")
  case "$verdict" in
    PASS) PASS=$((PASS + 1)) ;;
    FAIL) FAIL=$((FAIL + 1)) ;;
    SKIP) SKIP=$((SKIP + 1)) ;;
  esac
  {
    echo ""
    echo "### \`$svc\` · \`$step\` → **$verdict** (${seconds}s)"
    echo ""
    echo '```bash'
    echo "$cmd"
    echo '```'
    echo ""
    echo "<details><summary>stdout/stderr (${#out} bytes)</summary>"
    echo ""
    echo '```'
    printf '%s\n' "$preview"
    [[ ${#out} -gt 1200 ]] && echo "... [truncated, full file: $outfile]"
    echo '```'
    echo ""
    echo "</details>"
  } >>"$OUT_DIR/EVIDENCE.md"
}

run_step() {
  local svc="$1" step="$2" expect_regex="${3:-}" 
  shift 3
  local dir="$EV_DIR/$svc" cmdfile outfile rcfile start end rc cmd_disp
  mkdir -p "$dir"
  cmdfile="$dir/${step}.cmd"
  outfile="$dir/${step}.out"
  rcfile="$dir/${step}.rc"

  # skip if container missing
  local cname="infra-default-$svc"
  if ! docker ps --format '{{.Names}}' | grep -qx "$cname"; then
    echo "SKIP: container $cname not running" >"$outfile"
    echo 0 >"$rcfile"
    printf '%s\n' "$*" | redact >"$cmdfile"
    record "$svc" "$step" "SKIP" 0 "$(cat "$cmdfile")" "$outfile"
    return 0
  fi

  # record argv safely (shell-escaped) for audit replay
  { printf '%q ' "$@"; echo; } | redact >"$cmdfile"
  cmd_disp="$(cat "$cmdfile")"
  start="$(date +%s)"
  set +e
  "$@" >"$outfile" 2>&1
  rc=$?
  set -e
  end="$(date +%s)"
  echo "$rc" >"$rcfile"

  if [[ -n "$expect_regex" && "$rc" -eq 0 ]]; then
    if ! grep -qE "$expect_regex" "$outfile"; then
      rc=97
      echo "$rc" >"$rcfile"
      echo "[evidence] expect_regex failed: $expect_regex" >>"$outfile"
    fi
  fi

  if [[ "$rc" -eq 0 ]]; then
    record "$svc" "$step" "PASS" "$((end - start))" "$cmd_disp" "$outfile"
  else
    record "$svc" "$step" "FAIL" "$((end - start))" "$cmd_disp" "$outfile"
  fi
}

# ─── Header ──────────────────────────────────────────────────────────────────
{
  echo "# E2E Adherence Evidence"
  echo ""
  echo "| Field | Value |"
  echo "|---|---|"
  echo "| Generated (UTC) | $STAMP |"
  echo "| Token | \`$TOKEN\` |"
  echo "| Host | \`$(hostname)\` |"
  echo "| Repo | \`$ROOT\` |"
  echo "| Env file | \`$ENV_FILE\` |"
  echo "| Output | \`$OUT_DIR\` |"
  echo ""
  echo "Each step below is a **real command** executed against the live Docker stack."
  echo "Full outputs live under \`evidence/<service>/<step>.out\`."
  echo ""
  echo "## Steps"
} >"$OUT_DIR/EVIDENCE.md"

log_header "Adherence evidence · token=$TOKEN"
log_info "OUT=$OUT_DIR"

# ─── redis ───────────────────────────────────────────────────────────────────
run_step redis container-ping '' docker exec infra-default-redis redis-cli ping
run_step redis setget 'OK' docker exec infra-default-redis redis-cli SET "e2e:evidence:$TOKEN" "proof-$TOKEN" EX 120
run_step redis get "proof-$TOKEN" docker exec infra-default-redis redis-cli GET "e2e:evidence:$TOKEN"
run_step redis logs '' docker logs --tail 30 infra-default-redis

# ─── postgres ────────────────────────────────────────────────────────────────
run_step postgres ready 'accepting' docker exec infra-default-postgres \
  pg_isready -U "${POSTGRES_USER:-e2e}"
run_step postgres sql 'proof' docker exec infra-default-postgres \
  psql -U "${POSTGRES_USER:-e2e}" -d "${POSTGRES_DB:-e2e}" -v ON_ERROR_STOP=1 -c \
  "CREATE TABLE IF NOT EXISTS e2e_evidence(id serial primary key, note text, created_at timestamptz default now());
   INSERT INTO e2e_evidence(note) VALUES ('proof-$TOKEN');
   SELECT id, note, created_at FROM e2e_evidence WHERE note = 'proof-$TOKEN';"
run_step postgres logs '' docker logs --tail 20 infra-default-postgres

# ─── mongo ───────────────────────────────────────────────────────────────────
MU="${MONGO_INITDB_ROOT_USERNAME:-e2e}"
MP="${MONGO_INITDB_ROOT_PASSWORD:-e2e_pass_local}"
run_step mongo ping 'ok' docker exec infra-default-mongo \
  mongosh --quiet -u "$MU" -p "$MP" --authenticationDatabase admin \
  --eval 'JSON.stringify(db.adminCommand({ping:1}))'
run_step mongo crud "$TOKEN" docker exec infra-default-mongo \
  mongosh --quiet -u "$MU" -p "$MP" --authenticationDatabase admin --eval \
  "const r=db.getSiblingDB('e2e').evidence.insertOne({token:'$TOKEN',ok:true,at:new Date()});
   const doc=db.getSiblingDB('e2e').evidence.findOne({token:'$TOKEN'});
   print(JSON.stringify({insertedId:String(r.insertedId),found:doc},null,2));
   if(!doc) quit(1)"
run_step mongo logs '' docker logs --tail 20 infra-default-mongo

# ─── mysql ───────────────────────────────────────────────────────────────────
run_step mysql sql "$TOKEN" docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-e2e_root_local}" infra-default-mysql \
  mysql -uroot -e \
  "CREATE DATABASE IF NOT EXISTS e2e;
   USE e2e;
   CREATE TABLE IF NOT EXISTS e2e_evidence(id INT AUTO_INCREMENT PRIMARY KEY, note VARCHAR(128), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
   INSERT INTO e2e_evidence(note) VALUES ('proof-$TOKEN');
   SELECT id, note, created_at FROM e2e_evidence WHERE note='proof-$TOKEN';"
run_step mysql logs '' docker logs --tail 20 infra-default-mysql

# ─── rabbitmq ────────────────────────────────────────────────────────────────
RU="${RABBIT_USER:-e2e}"
RP="${RABBIT_PASSWORD:-e2e_pass_local}"
Q="e2e.evidence.$TOKEN"
run_step rabbitmq ping 'succeeded|pong' docker exec infra-default-rabbitmq rabbitmq-diagnostics -q ping
run_step rabbitmq declare-queue '' \
  curl -fsS -m 10 -u "$RU:$RP" -H 'content-type: application/json' \
  -X PUT "http://127.0.0.1:15672/api/queues/%2F/${Q}" \
  -d '{"durable":false,"auto_delete":true}'
run_step rabbitmq publish 'routed' \
  bash -c "curl -fsS -m 10 -u '$RU:$RP' -H 'content-type: application/json' \
    -X POST 'http://127.0.0.1:15672/api/exchanges/%2F/amq.default/publish' \
    -d '{\"properties\":{},\"routing_key\":\"$Q\",\"payload\":\"proof-$TOKEN\",\"payload_encoding\":\"string\"}'"
run_step rabbitmq consume "$TOKEN" \
  bash -c "curl -fsS -m 10 -u '$RU:$RP' -H 'content-type: application/json' \
    -X POST 'http://127.0.0.1:15672/api/queues/%2F/${Q}/get' \
    -d '{\"count\":1,\"ackmode\":\"ack_requeue_false\",\"encoding\":\"auto\"}'"
run_step rabbitmq logs '' docker logs --tail 20 infra-default-rabbitmq

# ─── prometheus ──────────────────────────────────────────────────────────────
run_step prometheus ready '' curl -fsS -m 8 http://127.0.0.1:9090/-/ready
run_step prometheus query-up 'success' \
  curl -fsS -m 8 --get --data-urlencode 'query=up' http://127.0.0.1:9090/api/v1/query
run_step prometheus targets 'activeTargets' \
  bash -c 'curl -fsS -m 8 http://127.0.0.1:9090/api/v1/targets | head -c 8000; echo'
run_step prometheus logs '' docker logs --tail 15 infra-default-prometheus

# ─── alertmanager ────────────────────────────────────────────────────────────
run_step alertmanager ready '' curl -fsS -m 8 http://127.0.0.1:9093/-/ready
run_step alertmanager status 'versionInfo' curl -fsS -m 8 http://127.0.0.1:9093/api/v2/status
run_step alertmanager alerts '' curl -fsS -m 8 http://127.0.0.1:9093/api/v2/alerts

# ─── exporters (grep signature lines — go_* headers come first) ──────────────
run_step node-exporter metrics 'node_cpu' \
  bash -c 'curl -fsS -m 8 http://127.0.0.1:9100/metrics | grep -E "^node_cpu" | head -20'
run_step blackbox-exporter metrics 'blackbox|probe_' \
  bash -c 'curl -fsS -m 8 http://127.0.0.1:9115/metrics | grep -E "blackbox|probe_" | head -20'
# probe target must be reachable FROM inside blackbox container (compose DNS)
run_step blackbox-exporter probe-prometheus 'probe_success 1' \
  curl -fsS -m 10 'http://127.0.0.1:9115/probe?target=http://prometheus:9090/-/ready&module=http_2xx'
run_step postgres-exporter metrics 'pg_' \
  bash -c 'curl -fsS -m 8 http://127.0.0.1:9187/metrics | grep -E "^pg_" | head -20'
run_step redis-exporter metrics 'redis_' \
  bash -c 'curl -fsS -m 8 http://127.0.0.1:9121/metrics | grep -E "^redis_" | head -20'
run_step mongodb-exporter metrics 'mongodb_|mongo_' \
  bash -c 'curl -fsS -m 8 http://127.0.0.1:9216/metrics | grep -Ei "mongodb_|mongo_" | head -20'
run_step mysql-exporter metrics 'mysql' \
  bash -c 'curl -fsS -m 8 http://127.0.0.1:9104/metrics | grep -Ei "^mysql" | head -20'

# ─── grafana ─────────────────────────────────────────────────────────────────
run_step grafana health 'ok' curl -fsS -m 8 http://127.0.0.1:3001/api/health
run_step grafana login-ui '' \
  bash -c 'c=$(curl -sS -m 10 -o /tmp/gf-login.out -w "%{http_code}" -L http://127.0.0.1:3001/login); echo "http_code=$c"; head -c 400 /tmp/gf-login.out; echo; [[ "$c" =~ ^[23] ]]'
run_step grafana datasources '' \
  bash -c 'curl -fsS -m 8 -u "${GF_SECURITY_ADMIN_USER:-admin}:${GF_SECURITY_ADMIN_PASSWORD:-e2e_pass_local}" http://127.0.0.1:3001/api/datasources'

# ─── vault ───────────────────────────────────────────────────────────────────
run_step vault seal-status 'sealed' curl -fsS -m 8 http://127.0.0.1:8200/v1/sys/seal-status
run_step vault health '' \
  bash -c 'c=$(curl -sS -m 5 -o /tmp/vault-h.out -w "%{http_code}" "http://127.0.0.1:8200/v1/sys/health?standbyok=true&uninitcode=200&sealedcode=200"); echo "http_code=$c"; cat /tmp/vault-h.out; echo; [[ "$c" =~ ^[23] ]]'

# ─── mailhog ─────────────────────────────────────────────────────────────────
run_step mailhog api-before 'total' curl -fsS -m 8 http://127.0.0.1:8025/api/v2/messages
run_step mailhog smtp-send '' python3 -c "
import smtplib
from email.message import EmailMessage
m=EmailMessage()
m['From']='evidence@example.com'
m['To']='sink@example.com'
m['Subject']='evidence-$TOKEN'
m.set_content('adherence-evidence-body-$TOKEN')
s=smtplib.SMTP('127.0.0.1',1025,timeout=10)
s.send_message(m)
s.quit()
print('smtp_sent=evidence-$TOKEN')
"
run_step mailhog api-after "$TOKEN" curl -fsS -m 8 http://127.0.0.1:8025/api/v2/messages

# ─── UIs ─────────────────────────────────────────────────────────────────────
run_step pgadmin ui '' \
  bash -c 'c=$(curl -sS -m 10 -o /tmp/pgadmin.out -w "%{http_code}" -L http://127.0.0.1:8088/login); echo "http_code=$c"; head -c 300 /tmp/pgadmin.out; echo; [[ "$c" =~ ^[23] ]]'
run_step phpmyadmin ui '' \
  bash -c 'c=$(curl -sS -m 10 -o /tmp/pma.out -w "%{http_code}" -L http://127.0.0.1:8082/); echo "http_code=$c"; head -c 300 /tmp/pma.out; echo; [[ "$c" =~ ^[23] ]]'
run_step redisinsight ui '' \
  bash -c 'c=$(curl -sS -m 10 -o /tmp/ri.out -w "%{http_code}" -L http://127.0.0.1:8083/); echo "http_code=$c"; head -c 300 /tmp/ri.out; echo; [[ "$c" =~ ^[23] ]]'
run_step mongo-express ui '' \
  bash -c 'c=$(curl -sS -m 10 -o /tmp/me.out -w "%{http_code}" -L -u "${ME_CONFIG_BASICAUTH_USERNAME:-e2e}:${ME_CONFIG_BASICAUTH_PASSWORD:-e2e_pass_local}" http://127.0.0.1:8081/); echo "http_code=$c"; head -c 300 /tmp/me.out; echo; [[ "$c" =~ ^[23] ]]'

# ─── Summary JSON + footer ───────────────────────────────────────────────────
python3 - "$OUT_DIR" "$STAMP" "$TOKEN" "$PASS" "$FAIL" "$SKIP" <<'PY'
import json, sys, pathlib, os
out = pathlib.Path(sys.argv[1])
stamp, token = sys.argv[2], sys.argv[3]
pass_, fail, skip = map(int, sys.argv[4:7])
rows = []
ev = out / "evidence"
for svc_dir in sorted(ev.iterdir() if ev.exists() else []):
    if not svc_dir.is_dir():
        continue
    svc = svc_dir.name
    steps = sorted({p.stem for p in svc_dir.glob("*.out")})
    for step in steps:
        rc_p = svc_dir / f"{step}.rc"
        out_p = svc_dir / f"{step}.out"
        cmd_p = svc_dir / f"{step}.cmd"
        rc = int(rc_p.read_text().strip()) if rc_p.exists() else 1
        raw = out_p.read_text(errors="replace") if out_p.exists() else ""
        cmd = cmd_p.read_text(errors="replace").strip() if cmd_p.exists() else ""
        if "SKIP: container" in raw:
            verdict = "SKIP"
        elif rc == 0:
            verdict = "PASS"
        else:
            verdict = "FAIL"
        rows.append({
            "service": svc,
            "step": step,
            "verdict": verdict,
            "rc": rc,
            "command": cmd,
            "stdout_preview": raw[:800],
            "stdout_bytes": len(raw),
            "stdout_path": str(out_p.relative_to(out)),
        })
services = {}
for r in rows:
    s = services.setdefault(r["service"], {"pass": 0, "fail": 0, "skip": 0, "steps": []})
    s[r["verdict"].lower()] = s.get(r["verdict"].lower(), 0) + 1
    s["steps"].append(r)

report = {
    "schema": "infra-devtools.adherence-evidence.v1",
    "generated_utc": stamp,
    "token": token,
    "totals": {
        "steps": len(rows),
        "pass": sum(1 for r in rows if r["verdict"] == "PASS"),
        "fail": sum(1 for r in rows if r["verdict"] == "FAIL"),
        "skip": sum(1 for r in rows if r["verdict"] == "SKIP"),
    },
    "services": services,
    "steps": rows,
}
(out / "evidence.json").write_text(json.dumps(report, indent=2) + "\n")
# summary footer for md
md = out / "EVIDENCE.md"
t = report["totals"]
with md.open("a") as f:
    f.write("\n\n## Totals\n\n")
    f.write(f"- **PASS**: {t['pass']}\n")
    f.write(f"- **FAIL**: {t['fail']}\n")
    f.write(f"- **SKIP**: {t['skip']}\n")
    f.write(f"- **Steps**: {t['steps']}\n")
    f.write(f"\nMachine-readable: `evidence.json`\n")
print(json.dumps(t))
PY

log_success "Evidence pack ready → $OUT_DIR/EVIDENCE.md"
log_info "JSON → $OUT_DIR/evidence.json"
python3 -c "import json,sys; t=json.load(open(sys.argv[1]))['totals']; print(t); sys.exit(0 if t['fail']==0 else 1)" \
  "$OUT_DIR/evidence.json"
