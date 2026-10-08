#!/usr/bin/env bash
################################################################################
# e2e-staged.sh — Orquestrador E2E serial (RAM + portas + probe por serviço)
#
# Fluxo por serviço (stages 1–5):
#   1) gate de memória
#   2) catálogo: 1 HOST_PORT → 1 serviço
#   3) preflight porta (livre | nossa | abort)
#   4) compose up -d <svc>
#   5) verify owner exato da(s) porta(s)
#   6) probe/teste daquele serviço
#   7) só então o próximo
#
# Usage:
#   bash scripts/e2e-staged.sh
#   bash scripts/e2e-staged.sh --max-stage 3
#   bash scripts/e2e-staged.sh --dry-run
#   bash scripts/e2e-staged.sh --adhere-only   # functional probes on stack already up
#   MIN_FREE_MB=256 POST_DOCKER_MIN_FREE_MB=128 E2E_PORT_POLICY=abort \
#     bash scripts/e2e-staged.sh
#
# Report: reports/e2e-staged/<UTC>/report.json
################################################################################
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# Prefer project venv so stage0 pytest/bandit match local SSOT
if [[ -x "$ROOT/.venv/bin/python3" ]]; then
  export PATH="$ROOT/.venv/bin:$PATH"
fi
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
# shellcheck source=lib-port-preflight.sh
. "$(dirname "$0")/lib-port-preflight.sh"

MIN_FREE_MB="${MIN_FREE_MB:-1536}"
POST_DOCKER_MIN_FREE_MB="${POST_DOCKER_MIN_FREE_MB:-192}"
MAX_STAGE="${MAX_STAGE:-5}"
DRY_RUN=0
ENV_FILE="${ENV_FILE:-.env}"
E2E_PORT_POLICY="${E2E_PORT_POLICY:-abort}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${E2E_OUT:-reports/e2e-staged/${STAMP}}"
mkdir -p "$OUT_DIR"
: >"$OUT_DIR/steps.jsonl"
: >"$OUT_DIR/memory-samples.jsonl"
PORT_CONFLICTS_LOG="$OUT_DIR/port-conflicts.jsonl"
: >"$PORT_CONFLICTS_LOG"
export ENV_FILE E2E_PORT_POLICY PORT_CONFLICTS_LOG

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-stage) MAX_STAGE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --env-file) ENV_FILE="$2"; shift 2 ;;
    --min-free-mb) MIN_FREE_MB="$2"; shift 2 ;;
    --port-policy) E2E_PORT_POLICY="$2"; shift 2 ;;
    --adhere-only) ADHERE_ONLY=1; shift ;;
    -h|--help) sed -n '2,28p' "$0"; exit 0 ;;
    *) log_error "Unknown arg: $1"; exit 2 ;;
  esac
done
ADHERE_ONLY="${ADHERE_ONLY:-0}"

# ─── Stages (ascending cost) ────────────────────────────────────────────────
STAGE1=(redis postgres mongo mysql)
STAGE2=(prometheus alertmanager node-exporter blackbox-exporter)
STAGE3=(postgres-exporter redis-exporter mongodb-exporter mysql-exporter grafana)
STAGE4=(rabbitmq vault)
STAGE5=(mailhog pgadmin phpmyadmin redisinsight mongo-express)

# ─── Helpers ────────────────────────────────────────────────────────────────
free_mb() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    # macOS keeps most RAM in inactive/purgeable; "Pages free" alone under-reports
    # ~100× vs reclaimable memory and falsely aborts Colima E2E waves.
    local ps pages
    ps="$(pagesize 2>/dev/null || echo 4096)"
    pages="$(vm_stat 2>/dev/null | awk '
      /Pages free/ {gsub(/\./,"",$3); f=$3}
      /Pages speculative/ {gsub(/\./,"",$3); s=$3}
      /Pages inactive/ {gsub(/\./,"",$3); i=$3}
      /Pages purgeable/ {gsub(/\./,"",$3); p=$3}
      END {print (f+0)+(s+0)+(i+0)+(p+0)}
    ')"
    echo $(( pages * ps / 1024 / 1024 ))
  elif [[ -r /proc/meminfo ]]; then
    awk '/MemAvailable:/ {printf "%d", $2/1024}' /proc/meminfo
  else
    echo 0
  fi
}

pressure_snapshot() {
  python3 - <<'PY'
import json, platform, subprocess
out = {"os": platform.system(), "free_mb": None, "phys_gb": None, "note": ""}
try:
    if platform.system() == "Darwin":
        try:
            ps = int(subprocess.check_output(["pagesize"], text=True).strip() or "4096")
        except Exception:
            ps = 4096
        vals = {}
        for line in subprocess.check_output(["vm_stat"], text=True).splitlines():
            if ":" not in line:
                continue
            k, v = line.split(":", 1)
            raw = v.strip().rstrip(".")
            if raw.isdigit():
                vals[k.strip()] = int(raw)
        # Align with free_mb(): reclaimable ≈ free + speculative + inactive + purgeable
        reclaim = (
            vals.get("Pages free", 0)
            + vals.get("Pages speculative", 0)
            + vals.get("Pages inactive", 0)
            + vals.get("Pages purgeable", 0)
        ) * ps / (1024 * 1024)
        out.update(
            free_mb=round(reclaim),
            free_strict_mb=round(
                (vals.get("Pages free", 0) + vals.get("Pages speculative", 0))
                * ps
                / (1024 * 1024)
            ),
            inactive_mb=round(vals.get("Pages inactive", 0) * ps / (1024 * 1024)),
            purgeable_mb=round(vals.get("Pages purgeable", 0) * ps / (1024 * 1024)),
            active_mb=round(vals.get("Pages active", 0) * ps / (1024 * 1024)),
            wired_mb=round(vals.get("Pages wired down", 0) * ps / (1024 * 1024)),
            compressor_mb=round(vals.get("Pages occupied by compressor", 0) * ps / (1024 * 1024)),
        )
        try:
            phys = int(subprocess.check_output(["sysctl", "-n", "hw.memsize"], text=True).strip())
            out["phys_gb"] = round(phys / 1e9, 1)
        except Exception:
            pass
    else:
        d = {}
        for line in open("/proc/meminfo"):
            k, v = line.split(":", 1)
            d[k] = int(v.strip().split()[0])
        out["free_mb"] = d.get("MemAvailable", 0) // 1024
        out["phys_gb"] = round(d.get("MemTotal", 0) / 1024 / 1024, 1)
except Exception as e:
    out["note"] = str(e)
print(json.dumps(out))
PY
}

docker_ok() { docker info >/dev/null 2>&1; }

compose() { docker compose --env-file "$ENV_FILE" "$@"; }

ensure_env() {
  [[ -f "$ENV_FILE" ]] && return 0
  log_warning "No $ENV_FILE — writing ephemeral local E2E env"
  cat >"$ENV_FILE" <<'EOF'
POSTGRES_USER=e2e
POSTGRES_PASSWORD=e2e_pass_local
POSTGRES_DB=e2e
MYSQL_ROOT_PASSWORD=e2e_root_local
MYSQL_DATABASE=e2e
MYSQL_USER=e2e
MYSQL_PASSWORD=e2e_pass_local
MONGO_INITDB_ROOT_USERNAME=e2e
MONGO_INITDB_ROOT_PASSWORD=e2e_pass_local
ME_CONFIG_MONGODB_SERVER=mongo
ME_CONFIG_MONGODB_PORT=27017
ME_CONFIG_MONGODB_ADMINUSERNAME=e2e
ME_CONFIG_MONGODB_ADMINPASSWORD=e2e_pass_local
ME_CONFIG_MONGODB_AUTH_DATABASE=admin
ME_CONFIG_BASICAUTH_USERNAME=e2e
ME_CONFIG_BASICAUTH_PASSWORD=e2e_pass_local
ME_CONFIG_MONGODB_ENABLE_ADMIN=true
ME_CONFIG_MONGODB_USE_UNIFIED_TOPOLOGY=true
PGADMIN_DEFAULT_EMAIL=e2e@example.com
PGADMIN_DEFAULT_PASSWORD=e2e_pass_local
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=e2e_pass_local
GF_AUTH_DISABLE_LOGIN_FORM=false
GF_AUTH_ANONYMOUS_ENABLED=false
REDIS_ADDR=redis:6379
RABBIT_USER=e2e
RABBIT_PASSWORD=e2e_pass_local
RABBIT_URL=amqp://e2e:e2e_pass_local@rabbitmq:5672/
VAULT_ADDR=http://127.0.0.1:8200
PMA_HOST=mysql
PMA_PORT=3306
PMA_PASSWORD=e2e_pass_local
SONARQUBE_JVM_OPTIONS=-Xmx512m
SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
EOF
}

ensure_networks() {
  docker network inspect spring-shared-net >/dev/null 2>&1 || docker network create spring-shared-net >/dev/null
}

gate_memory() {
  local label="$1" need="${2:-$MIN_FREE_MB}" free
  free="$(free_mb)"
  echo "{\"stage\":\"$label\",\"free_mb\":$free,\"min_required_mb\":$need,\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" \
    >>"$OUT_DIR/memory-samples.jsonl"
  if [[ "$free" -lt "$need" ]]; then
    log_error "memory gate FAIL [$label] free=${free}MB need≥${need}MB"
    return 1
  fi
  log_success "memory gate OK [$label] free=${free}MB"
}

run_cmd() {
  local name="$1"; shift
  local logf="$OUT_DIR/${name}.log" start end rc had_e=0
  [[ $- == *e* ]] && had_e=1
  start="$(date +%s)"
  set +e
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "DRY-RUN: $*" | tee "$logf"; rc=0
  else
    "$@" >"$logf" 2>&1; rc=$?
  fi
  end="$(date +%s)"
  echo "{\"name\":\"$name\",\"rc\":$rc,\"seconds\":$((end - start)),\"log\":\"${name}.log\"}" >>"$OUT_DIR/steps.jsonl"
  if [[ "$rc" -eq 0 ]]; then
    log_success "$name OK ($((end - start))s)"
  else
    log_error "$name FAIL rc=$rc — $logf"
  fi
  [[ "$had_e" -eq 1 ]] && set -e
  # Return via status only; callers under set -e must use `if ! run_cmd` / `|| true`
  return "$rc"
}

wait_http() {
  local url="$1" tries="${2:-20}" code i
  for ((i = 1; i <= tries; i++)); do
    code="$(curl -sS -m 5 -o /dev/null -w '%{http_code}' -L "$url" 2>/dev/null || echo 000)"
    [[ "$code" =~ ^[23][0-9][0-9]$ ]] && return 0
    sleep 2
  done
  return 1
}

# --- Adherence: functional checks per service (not just /ready) ---
check_service_logs() {
  local svc="$1" cname="${INFRA_CONTAINER_PREFIX:-infra-default-}$1"
  local logf="$OUT_DIR/logs-${svc}.txt"
  docker logs --tail 80 "$cname" >"$logf" 2>&1 || true
  # Fail only on clear fatal patterns (ignore noisy WARN during boot)
  if grep -qiE 'fatal error|panic:|oom-kill|cannot allocate memory' "$logf"; then
    log_error "logs-$svc contain fatal patterns — see $logf"
    return 1
  fi
  log_success "logs-$svc captured ($(wc -l <"$logf" | tr -d ' ') lines)"
  echo "{\"name\":\"logs-$svc\",\"rc\":0,\"seconds\":0,\"log\":\"logs-${svc}.txt\"}" >>"$OUT_DIR/steps.jsonl"
  return 0
}

# Probe + functional adherence for ONE service (never aborts the orchestrator)
probe_one_service() {
  local svc="$1"
  local stamp fail=0
  stamp="$(date -u +%Y%m%d%H%M%S)"

  set +e
  check_service_logs "$svc" || fail=1

  case "$svc" in
    redis)
      run_cmd "probe-$svc-ping" compose exec -T redis redis-cli ping || fail=1
      run_cmd "probe-$svc-setget" compose exec -T redis redis-cli SET "e2e:adherence:$stamp" "ok" EX 60 || fail=1
      run_cmd "probe-$svc-get" compose exec -T redis redis-cli GET "e2e:adherence:$stamp" || fail=1
      run_cmd "probe-$svc-assert" bash -c "docker compose --env-file \"$ENV_FILE\" exec -T redis redis-cli GET e2e:adherence:$stamp | grep -qx ok" || fail=1
      ;;
    postgres)
      run_cmd "probe-$svc-ready" compose exec -T postgres pg_isready -U "${POSTGRES_USER:-e2e}" || fail=1
      run_cmd "probe-$svc-sql" compose exec -T postgres \
        psql -U "${POSTGRES_USER:-e2e}" -d "${POSTGRES_DB:-e2e}" -v ON_ERROR_STOP=1 -c \
        "CREATE TABLE IF NOT EXISTS e2e_adherence(id serial primary key, note text); INSERT INTO e2e_adherence(note) VALUES ('$stamp'); SELECT count(*) FROM e2e_adherence;" || fail=1
      ;;
    mongo)
      local mu mp
      mu="${MONGO_INITDB_ROOT_USERNAME:-e2e}"
      mp="${MONGO_INITDB_ROOT_PASSWORD:-e2e_pass_local}"
      run_cmd "probe-$svc-ping" compose exec -T mongo mongosh --quiet -u "$mu" -p "$mp" --authenticationDatabase admin --eval 'db.adminCommand({ping:1})' || fail=1
      run_cmd "probe-$svc-crud" compose exec -T mongo mongosh --quiet -u "$mu" -p "$mp" --authenticationDatabase admin --eval \
        "db.getSiblingDB('e2e').adherence.insertOne({ts:'$stamp',ok:true}); const n=db.getSiblingDB('e2e').adherence.countDocuments({ts:'$stamp'}); if(n<1) quit(1)" || fail=1
      ;;
    mysql)
      run_cmd "probe-$svc-sql" compose exec -T -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-e2e_root_local}" mysql \
        mysql -uroot -e "CREATE DATABASE IF NOT EXISTS e2e; USE e2e; CREATE TABLE IF NOT EXISTS e2e_adherence(id INT AUTO_INCREMENT PRIMARY KEY, note VARCHAR(64)); INSERT INTO e2e_adherence(note) VALUES ('$stamp'); SELECT COUNT(*) FROM e2e_adherence;" || fail=1
      ;;
    prometheus)
      run_cmd "probe-$svc-ready" bash -c 'for i in $(seq 1 15); do curl -fsS -m 5 http://127.0.0.1:9090/-/ready && exit 0; sleep 2; done; exit 1' || fail=1
      run_cmd "probe-$svc-query" bash -c 'curl -fsS -m 8 --get --data-urlencode "query=up" http://127.0.0.1:9090/api/v1/query | grep -q "\"status\":\"success\""' || fail=1
      run_cmd "probe-$svc-targets" bash -c 'curl -fsS -m 8 http://127.0.0.1:9090/api/v1/targets | grep -q activeTargets' || fail=1
      ;;
    alertmanager)
      run_cmd "probe-$svc-ready" bash -c 'for i in $(seq 1 15); do curl -fsS -m 5 http://127.0.0.1:9093/-/ready && exit 0; sleep 2; done; exit 1' || fail=1
      run_cmd "probe-$svc-status" bash -c 'curl -fsS -m 8 http://127.0.0.1:9093/api/v2/status | grep -q versionInfo' || fail=1
      run_cmd "probe-$svc-alerts" bash -c 'curl -fsS -m 8 http://127.0.0.1:9093/api/v2/alerts | grep -q "^\["' || fail=1
      ;;
    node-exporter)
      run_cmd "probe-$svc-metrics" bash -c 'curl -fsS -m 8 http://127.0.0.1:9100/metrics | grep -q node_cpu' || fail=1
      ;;
    blackbox-exporter)
      run_cmd "probe-$svc-metrics" bash -c 'curl -fsS -m 8 http://127.0.0.1:9115/metrics | grep -q blackbox' || fail=1
      run_cmd "probe-$svc-probe" bash -c 'curl -fsS -m 10 "http://127.0.0.1:9115/probe?target=http://127.0.0.1:9090/-/ready&module=http_2xx" | grep -q probe_success' || fail=1
      ;;
    postgres-exporter)
      run_cmd "probe-$svc-metrics" bash -c 'curl -fsS -m 8 http://127.0.0.1:9187/metrics | grep -q pg_' || fail=1
      ;;
    redis-exporter)
      run_cmd "probe-$svc-metrics" bash -c 'curl -fsS -m 8 http://127.0.0.1:9121/metrics | grep -q redis_' || fail=1
      ;;
    mongodb-exporter)
      run_cmd "probe-$svc-metrics" bash -c 'curl -fsS -m 8 http://127.0.0.1:9216/metrics | head -c 400 | grep -q .' || fail=1
      ;;
    mysql-exporter)
      run_cmd "probe-$svc-metrics" bash -c 'curl -fsS -m 8 http://127.0.0.1:9104/metrics | grep -q mysql' || fail=1
      ;;
    grafana)
      run_cmd "probe-$svc-health" bash -c 'curl -fsS -m 8 http://127.0.0.1:3001/api/health | grep -q ok' || fail=1
      run_cmd "probe-$svc-login-ui" bash -c 'c=$(curl -sS -m 10 -o /dev/null -w "%{http_code}" -L http://127.0.0.1:3001/login); [[ "$c" =~ ^[23] ]]' || fail=1
      run_cmd "probe-$svc-datasources" bash -c 'curl -fsS -m 8 -u "${GF_SECURITY_ADMIN_USER:-admin}:${GF_SECURITY_ADMIN_PASSWORD:-e2e_pass_local}" http://127.0.0.1:3001/api/datasources | grep -q "^\["' || fail=1
      ;;
    rabbitmq)
      run_cmd "probe-$svc-ping" compose exec -T rabbitmq rabbitmq-diagnostics -q ping || fail=1
      run_cmd "probe-$svc-queue" bash -c "curl -fsS -m 8 -u \"${RABBIT_USER:-e2e}:${RABBIT_PASSWORD:-e2e_pass_local}\" -H 'content-type: application/json' -X PUT \"http://127.0.0.1:15672/api/queues/%2F/e2e.adherence.$stamp\" -d '{\"durable\":false,\"auto_delete\":true}'" || fail=1
      run_cmd "probe-$svc-publish" bash -c "curl -fsS -m 8 -u \"${RABBIT_USER:-e2e}:${RABBIT_PASSWORD:-e2e_pass_local}\" -H 'content-type: application/json' -X POST http://127.0.0.1:15672/api/exchanges/%2F/amq.default/publish -d '{\"properties\":{},\"routing_key\":\"e2e.adherence.$stamp\",\"payload\":\"hello-$stamp\",\"payload_encoding\":\"string\"}' | grep -q '\"routed\":true'" || fail=1
      run_cmd "probe-$svc-get" bash -c "curl -fsS -m 8 -u \"${RABBIT_USER:-e2e}:${RABBIT_PASSWORD:-e2e_pass_local}\" -H 'content-type: application/json' -X POST \"http://127.0.0.1:15672/api/queues/%2F/e2e.adherence.$stamp/get\" -d '{\"count\":1,\"ackmode\":\"ack_requeue_false\",\"encoding\":\"auto\"}' | grep -q hello-$stamp" || fail=1
      ;;
    vault)
      run_cmd "probe-$svc-seal" bash -c 'curl -fsS -m 8 http://127.0.0.1:8200/v1/sys/seal-status | grep -q sealed' || fail=1
      run_cmd "probe-$svc-health" bash -c 'c=$(curl -sS -m 5 -o /tmp/vault.h -w "%{http_code}" "http://127.0.0.1:8200/v1/sys/health?standbyok=true&uninitcode=200&sealedcode=200"); [[ "$c" =~ ^[23] ]]' || fail=1
      ;;
    mailhog)
      run_cmd "probe-$svc-api" bash -c 'curl -fsS -m 8 http://127.0.0.1:8025/api/v2/messages | grep -q total' || fail=1
      run_cmd "probe-$svc-smtp" python3 -c "
import smtplib
from email.message import EmailMessage
m=EmailMessage(); m['From']='e2e@example.com'; m['To']='sink@example.com'; m['Subject']='e2e-$stamp'; m.set_content('adherence')
s=smtplib.SMTP('127.0.0.1',1025,timeout=10); s.send_message(m); s.quit()
" || fail=1
      run_cmd "probe-$svc-msg" bash -c 'curl -fsS -m 8 http://127.0.0.1:8025/api/v2/messages | grep -q e2e-'"$stamp" || fail=1
      ;;
    pgadmin)
      run_cmd "probe-$svc-ui" bash -c 'c=$(curl -sS -m 10 -o /dev/null -w "%{http_code}" -L http://127.0.0.1:8088/login); [[ "$c" =~ ^[23] ]]' || fail=1
      ;;
    phpmyadmin)
      run_cmd "probe-$svc-ui" bash -c 'c=$(curl -sS -m 10 -o /dev/null -w "%{http_code}" -L http://127.0.0.1:8082/); [[ "$c" =~ ^[23] ]]' || fail=1
      ;;
    redisinsight)
      run_cmd "probe-$svc-ui" bash -c 'c=$(curl -sS -m 10 -o /dev/null -w "%{http_code}" -L http://127.0.0.1:8083/); [[ "$c" =~ ^[23] ]]' || fail=1
      ;;
    mongo-express)
      run_cmd "probe-$svc-ui" bash -c 'c=$(curl -sS -m 10 -o /dev/null -w "%{http_code}" -L -u "${ME_CONFIG_BASICAUTH_USERNAME:-e2e}:${ME_CONFIG_BASICAUTH_PASSWORD:-e2e_pass_local}" http://127.0.0.1:8081/); [[ "$c" =~ ^[23] ]]' || fail=1
      ;;
    *)
      log_info "probe: $svc — ownership verified only"
      ;;
  esac
  return "$fail"
}

# Run adherence against already-up services (no compose up)
run_adherence_pass() {
  local svc cname
  log_header "Adherence pass (functional) on running infra-default-* services"
  for svc in redis postgres mongo mysql prometheus alertmanager node-exporter blackbox-exporter \
             postgres-exporter redis-exporter mongodb-exporter mysql-exporter grafana \
             rabbitmq vault mailhog pgadmin phpmyadmin redisinsight mongo-express; do
    cname="${INFRA_CONTAINER_PREFIX:-infra-default-}$svc"
    if ! docker ps --format '{{.Names}}' | grep -qx "$cname"; then
      log_warning "skip adherence $svc — container not running"
      continue
    fi
    if ! verify_service_ports_owned "$svc" 5; then
      log_error "adherence blocked $svc — wrong port owner"
      continue
    fi
    log_header "Adherence · $svc"
    set +e
    probe_one_service "$svc"
    set -e
  done
}

# One stage = N services, each fully gated before the next
run_stage() {
  local n="$1" need="$2"
  shift 2
  local services=("$@") svc wave_need

  [[ -n "$ABORT_REASON" || "$MAX_STAGE" -lt "$n" ]] && return 0

  wave_need="$need"
  docker_ok && wave_need="$POST_DOCKER_MIN_FREE_MB"
  if ! gate_memory "$n" "$wave_need"; then
    ABORT_REASON="stage${n}_memory"
    return 0
  fi

  if ! assert_unique_port_catalog; then
    ABORT_REASON="stage${n}_port_catalog"
    return 0
  fi

  preflight_wave_inventory "stage$n" "${services[@]}" | tee "$OUT_DIR/stage${n}-port-preflight.txt"

  for svc in "${services[@]}"; do
    if ! gate_memory "${n}-${svc}" "$POST_DOCKER_MIN_FREE_MB"; then
      ABORT_REASON="stage${n}_${svc}_memory"
      return 0
    fi

    log_header "Stage $n · $svc"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log_info "DRY-RUN bring_up $svc"
      continue
    fi

    if ! bring_up_one_service "$svc"; then
      ABORT_REASON="stage${n}_${svc}_port_or_up"
      log_error "Stopped at $svc — remaining services in stage $n+ skipped"
      return 0
    fi
    log_info "bring_up status=$LAST_BRING_UP_STATUS for $svc"

    set +e
    probe_one_service "$svc"
    local probe_rc=$?
    set -e
    if [[ "$probe_rc" -ne 0 ]]; then
      log_warning "probe failed for $svc (continuing to next service in stage)"
    fi
  done

  REACHED="$n"
  run_cmd "stage${n}-ps" compose ps "${services[@]}" || true
}

write_report() {
  pressure_snapshot >"$OUT_DIR/pressure-end.json"
  python3 - "$OUT_DIR" "$REACHED" "${ABORT_REASON:-}" "$MIN_FREE_MB" "$MAX_STAGE" <<'PY'
import json, sys
from pathlib import Path
out = Path(sys.argv[1])
reached, abort, min_free, max_stage = int(sys.argv[2]), sys.argv[3], int(sys.argv[4]), int(sys.argv[5])

def load_jsonl(p):
    rows = []
    if not p.exists():
        return rows
    for i, line in enumerate(p.read_text().splitlines(), 1):
        line = line.strip()
        if not line.startswith("{"):
            continue
        try:
            rows.append(json.loads(line))
        except json.JSONDecodeError as e:
            rows.append({"parse_error": str(e), "line": i})
    return rows

def load_json(p):
    if not p.exists():
        return {}
    try:
        return json.loads(p.read_text())
    except json.JSONDecodeError as e:
        return {"parse_error": str(e)}

steps = load_jsonl(out / "steps.jsonl")
report = {
    "schema": "infra-devtools.e2e-staged.v2",
    "reached_stage": reached,
    "max_stage_requested": max_stage,
    "abort_reason": abort or None,
    "min_free_mb_policy": min_free,
    "docker_status": (out / "docker-status.txt").read_text().strip() if (out / "docker-status.txt").exists() else "unknown",
    "pressure_start": load_json(out / "pressure-start.json"),
    "pressure_end": load_json(out / "pressure-end.json"),
    "memory_samples": load_jsonl(out / "memory-samples.jsonl"),
    "port_conflicts": load_jsonl(out / "port-conflicts.jsonl"),
    "steps": steps,
    "summary": {
        "steps_total": len(steps),
        "steps_passed": sum(1 for s in steps if s.get("rc") == 0),
        "steps_failed": sum(1 for s in steps if isinstance(s.get("rc"), int) and s["rc"] not in (0, 77)),
        "containers_exercised": reached >= 1,
    },
}
(out / "report.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report["summary"], indent=2))
print("abort_reason=", abort or "none")
print("reached_stage=", reached)
print("report=", out / "report.json")
PY
}

# ─── Main ───────────────────────────────────────────────────────────────────
log_header "E2E staged orchestrator v2"
log_info "OUT=$OUT_DIR MAX_STAGE=$MAX_STAGE MIN_FREE=$MIN_FREE_MB POST_DOCKER=$POST_DOCKER_MIN_FREE_MB POLICY=$E2E_PORT_POLICY ADHERE_ONLY=$ADHERE_ONLY"
pressure_snapshot | tee "$OUT_DIR/pressure-start.json" >/dev/null

ABORT_REASON=""
REACHED=0

# Adherence-only: exercise already-running stack functionally (no compose up waves)
if [[ "$ADHERE_ONLY" -eq 1 ]]; then
  if ! docker_ok; then
    log_error "Docker unavailable"
    exit 1
  fi
  echo "docker_ok" >"$OUT_DIR/docker-status.txt"
  ensure_env
  set -a; [[ -f "$ENV_FILE" ]] && . "$ENV_FILE"; set +a
  assert_unique_port_catalog || true
  run_adherence_pass
  REACHED=5
  write_report
  log_success "Adherence-only pass finished — see $OUT_DIR/report.json"
  exit 0
fi

# Stage 0 — unit + static (no Docker); low bar (tests are local processes)
if gate_memory 0 16; then
  run_cmd stage0-unit python3 -m pytest -m unit --ignore=src/tests/integration -q \
    --tb=line --junitxml="$OUT_DIR/junit-unit.xml" || true
  run_cmd stage0-bashn bash -c 'f=0; for s in scripts/*.sh; do bash -n "$s" || f=1; done; exit $f' || true
  if command -v yamllint >/dev/null 2>&1 || python3 -c "import yamllint" 2>/dev/null; then
    run_cmd stage0-yamllint bash -c '
      CFG="{extends: default, rules: {line-length: disable, truthy: disable, comments: disable, document-start: disable, indentation: disable, new-line-at-end-of-file: disable}}"
      yamllint -d "$CFG" docker-compose.yml prometheus.yml alerts.yml alertmanager.yml blackbox.yml 2>/dev/null \
        || python3 -m yamllint -d "$CFG" docker-compose.yml prometheus.yml alerts.yml alertmanager.yml blackbox.yml
    ' || true
  fi
  run_cmd stage0-bandit python3 -m bandit -r src/ -ll -ii || true
  run_cmd stage0-compose-ports bash scripts/check-port-conflicts.sh --mode catalog || true
else
  ABORT_REASON="stage0_memory"
fi

# Docker readiness for container stages
if [[ -z "$ABORT_REASON" && "$MAX_STAGE" -ge 1 ]]; then
  if ! docker_ok; then
    ABORT_REASON="docker_unavailable"
    echo "docker_info_error" >"$OUT_DIR/docker-status.txt"
    docker info >"$OUT_DIR/docker-info.log" 2>&1 || true
    colima status >"$OUT_DIR/colima-status.log" 2>&1 || true
    log_error "Docker/Colima unavailable — stages 1–5 skipped"
  else
    echo "docker_ok" >"$OUT_DIR/docker-status.txt"
    ensure_env
    set -a; # shellcheck disable=SC1090
    [[ -f "$ENV_FILE" ]] && . "$ENV_FILE"
    set +a
    ensure_networks
  fi
fi

run_stage 1 512 "${STAGE1[@]}"
run_stage 2 512 "${STAGE2[@]}"
run_stage 3 512 "${STAGE3[@]}"
run_stage 4 768 "${STAGE4[@]}"
run_stage 5 768 "${STAGE5[@]}"

# Final health only for what we actually reached (scoped to e2e waves)
if docker_ok && [[ "$REACHED" -ge 1 ]]; then
  run_cmd final-health-endpoints \
    env HEALTH_CHECK_SCOPE=e2e-staged bash scripts/health-check.sh endpoints || true
  run_cmd final-health-databases bash scripts/health-check.sh databases || true
fi

write_report

if [[ -n "$ABORT_REASON" ]]; then
  log_warning "Partial run — abort_reason=$ABORT_REASON reached_stage=$REACHED"
  exit 0
fi
log_success "E2E staged complete — reached stage $REACHED"
exit 0
