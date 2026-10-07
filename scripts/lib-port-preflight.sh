#!/usr/bin/env bash
################################################################################
# Port / container conflict preflight — shared by ALL test & compose entrypoints.
#
# Source after lib.sh:
#   . "$(dirname "$0")/lib-port-preflight.sh"
#
# Or CLI:
#   bash scripts/check-port-conflicts.sh --mode start [--services a,b] [--policy abort|stop-foreign]
#   bash scripts/check-port-conflicts.sh --mode test
#
# Modes:
#   start — before compose up: abort (or stop-foreign) if port held by non-ours
#   test  — before integration: busy ports must belong to infra-default-* (or be free
#           only if the service is optional); foreign holders → fail closed
################################################################################

# Avoid double-source
if [[ "${_LIB_PORT_PREFLIGHT_LOADED:-0}" -eq 1 ]]; then
  return 0 2>/dev/null || true
fi
_LIB_PORT_PREFLIGHT_LOADED=1

E2E_PORT_POLICY="${E2E_PORT_POLICY:-abort}"
INFRA_CONTAINER_PREFIX="${INFRA_CONTAINER_PREFIX:-infra-default-}"
PORT_CONFLICTS_LOG="${PORT_CONFLICTS_LOG:-}"

# Canonical host ports published by docker-compose.yml (service → ports)
infra_all_services() {
  echo "redis postgres mongo mysql prometheus alertmanager node-exporter blackbox-exporter postgres-exporter redis-exporter mongodb-exporter mysql-exporter grafana rabbitmq vault mailhog pgadmin phpmyadmin redisinsight mongo-express"
}

service_host_ports() {
  case "$1" in
    redis) echo "6379" ;;
    postgres) echo "5432" ;;
    mongo) echo "27017" ;;
    mysql) echo "3306" ;;
    prometheus) echo "9090" ;;
    alertmanager) echo "9093" ;;
    node-exporter) echo "9100" ;;
    blackbox-exporter) echo "9115" ;;
    postgres-exporter) echo "9187" ;;
    redis-exporter) echo "9121" ;;
    mongodb-exporter) echo "9216" ;;
    mysql-exporter) echo "9104" ;;
    grafana) echo "3001" ;;
    rabbitmq) echo "5672 15672" ;;
    vault) echo "8200" ;;
    mailhog) echo "1025 8025" ;;
    pgadmin) echo "8088" ;;
    phpmyadmin) echo "8082" ;;
    redisinsight) echo "8083" ;;
    mongo-express) echo "8081" ;;
    cadvisor) echo "8080" ;;
    portainer) echo "9001" ;;
    sonarqube) echo "9000" ;;
    keycloak) echo "8099" ;;
    webhook-listener) echo "5001" ;;
    *) echo "" ;;
  esac
}

service_container_name() {
  # compose service name → container_name (mongo stays mongo, not mongodb)
  case "$1" in
    *) echo "${INFRA_CONTAINER_PREFIX}$1" ;;
  esac
}

port_listening() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
    return $?
  fi
  (echo >/dev/tcp/127.0.0.1/"$port") >/dev/null 2>&1
}

port_holder_info() {
  local port="$1"
  local cname
  cname="$(docker ps --format '{{.Names}}\t{{.Ports}}' 2>/dev/null | awk -v p=":$port->" -F '\t' 'index($2,p){print $1; exit}')"
  if [[ -n "$cname" ]]; then
    echo "docker:$cname"
    return 0
  fi
  if command -v lsof >/dev/null 2>&1; then
    local proc
    proc="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | awk 'NR==2{print $1":"$2; exit}')"
    if [[ -n "$proc" ]]; then
      echo "proc:$proc"
      return 0
    fi
  fi
  echo "unknown"
}

container_running() {
  local name="$1"
  docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$name"
}

is_exact_holder() {
  local holder="$1" expected_cname="$2"
  [[ "$holder" == docker:"$expected_cname" ]]
}

is_our_holder() {
  local holder="$1" expected_cname="${2:-}"
  is_exact_holder "$holder" "$expected_cname" && return 0
  [[ "$holder" == docker:"${INFRA_CONTAINER_PREFIX}"* ]] && return 0
  return 1
}

record_port_conflict() {
  local svc="$1" port="$2" holder="$3" action="$4"
  local line
  line="$(printf '{"service":"%s","port":%s,"holder":"%s","action":"%s","ts":"%s"}\n' \
    "$svc" "$port" "$holder" "$action" "$(date -u +%Y-%m-%dT%H:%M:%SZ)")"
  if [[ -n "$PORT_CONFLICTS_LOG" ]]; then
    mkdir -p "$(dirname "$PORT_CONFLICTS_LOG")"
    echo "$line" >>"$PORT_CONFLICTS_LOG"
  fi
  echo "$line"
}

# Fail if docker-compose.yml maps the same HOST port to two services.
# Best practice: one HOST_PORT → one service (Docker bind; Compose merge collisions).
# Refs:
#   https://docs.docker.com/compose/how-tos/networking/  (HOST_PORT vs CONTAINER_PORT)
#   https://www.local-environment-automation.com/.../fixing-port-is-already-allocated-errors-in-compose/
assert_compose_host_ports_unique() {
  local compose_file="${COMPOSE_FILE:-docker-compose.yml}"
  local py_out
  if [[ ! -f "$compose_file" ]]; then
    log_warning "compose file not found: $compose_file — skip static port uniqueness check"
    return 0
  fi
  py_out="$(COMPOSE_FILE="$compose_file" python3 - <<'PY'
import os, re, sys
from collections import defaultdict
path = os.environ.get("COMPOSE_FILE", "docker-compose.yml")
text = open(path, encoding="utf-8").read()
ports = defaultdict(list)
svc = None
in_ports = False
for line in text.splitlines():
    m = re.match(r"^  ([a-zA-Z0-9_-]+):\s*$", line)
    if m:
        svc = m.group(1)
        in_ports = False
        continue
    if re.match(r"^\s+ports:\s*$", line):
        in_ports = True
        continue
    if in_ports:
        pm = re.search(r"""['\"]?(?:(?:\d+\.){3}\d+:)?(\d+):(\d+)""", line)
        if pm and svc:
            ports[int(pm.group(1))].append(svc)
        elif line.strip() and not line.strip().startswith("-") and not line.strip().startswith("#"):
            in_ports = False
dups = {p: sorted(set(svcs)) for p, svcs in ports.items() if len(set(svcs)) > 1}
if dups:
    for p, svcs in sorted(dups.items()):
        print(f"DUP {p} {' '.join(svcs)}")
    sys.exit(1)
print(f"OK {len(ports)}")
sys.exit(0)
PY
)" || {
    log_error "COMPOSE host-port uniqueness FAILED — two services share a host port:"
    echo "$py_out" >&2
    return 1
  }
  log_success "Compose host ports unique ($py_out)"
  return 0
}

# Fail if the static catalog maps the same host port to two different services.
assert_unique_port_catalog() {
  local svc ports port seen="" pair owner
  # Always validate the real compose file first (source of truth)
  if ! assert_compose_host_ports_unique; then
    return 1
  fi
  for svc in $(infra_all_services) cadvisor portainer sonarqube keycloak webhook-listener; do
    ports="$(service_host_ports "$svc")"
    for port in $ports; do
      [[ -z "$port" ]] && continue
      owner=""
      for pair in $seen; do
        if [[ "${pair%%:*}" == "$port" ]]; then
          owner="${pair#*:}"
          break
        fi
      done
      if [[ -n "$owner" && "$owner" != "$svc" ]]; then
        log_error "CATALOG conflict: host port $port claimed by both '$owner' and '$svc'"
        record_port_conflict "$svc" "$port" "catalog:$owner" "duplicate_catalog" >/dev/null
        return 1
      fi
      if [[ -z "$owner" ]]; then
        seen="$seen $port:$svc"
      fi
    done
  done
  log_success "Port catalog unique (no host port shared by two services)"
  return 0
}

# After compose up: every published port of THIS service must be held by THIS container.
verify_service_ports_owned() {
  local svc="$1"
  local cname ports port holder tries="${2:-15}" i
  cname="$(service_container_name "$svc")"
  ports="$(service_host_ports "$svc")"
  for port in $ports; do
    [[ -z "$port" ]] && continue
    for ((i=1; i<=tries; i++)); do
      if port_listening "$port"; then
        holder="$(port_holder_info "$port")"
        if is_exact_holder "$holder" "$cname"; then
          log_success "verify $svc — :$port owned by $cname"
          break
        fi
        log_error "verify $svc — :$port held by $holder (expected docker:$cname)"
        record_port_conflict "$svc" "$port" "$holder" "post_up_wrong_owner" >/dev/null
        return 1
      fi
      sleep 1
    done
    if ! port_listening "$port"; then
      log_error "verify $svc — :$port not listening after up"
      record_port_conflict "$svc" "$port" "none" "post_up_not_listening" >/dev/null
      return 1
    fi
  done
  return 0
}

# Before compose up for one service.
# rc 0 = ok to up; 1 = blocked; 2 = already ours (reuse / skip up)
preflight_service_start() {
  local svc="$1"
  local cname ports port holder
  cname="$(service_container_name "$svc")"
  ports="$(service_host_ports "$svc")"

  if container_running "$cname"; then
    # Still confirm ports belong to US exactly (no hijack / remap)
    if verify_service_ports_owned "$svc" 3; then
      log_info "preflight(start) $svc — $cname already running + ports owned; reuse"
      record_port_conflict "$svc" 0 "self:$cname" "reuse" >/dev/null
      return 2
    fi
    log_error "preflight(start) $svc — container up but port ownership mismatch"
    return 1
  fi

  for port in $ports; do
    [[ -z "$port" ]] && continue
    if ! port_listening "$port"; then
      continue
    fi
    holder="$(port_holder_info "$port")"
    if is_exact_holder "$holder" "$cname"; then
      continue
    fi
    # Sibling infra-default-* on the same port = hard conflict (duplicate mapping / wrong owner)
    if [[ "$holder" == docker:"${INFRA_CONTAINER_PREFIX}"* ]]; then
      log_error "preflight(start) $svc — port $port already owned by sibling $holder (cannot share host port)"
      record_port_conflict "$svc" "$port" "$holder" "abort_sibling" >/dev/null
      return 1
    fi
    log_error "preflight(start) $svc — port $port BUSY ($holder)"
    case "${E2E_PORT_POLICY}" in
      stop-foreign)
        if [[ "$holder" == docker:* ]]; then
          local stop_name="${holder#docker:}"
          log_warning "E2E_PORT_POLICY=stop-foreign — stopping $stop_name"
          docker stop "$stop_name" >/dev/null 2>&1 || true
          sleep 1
          if port_listening "$port"; then
            record_port_conflict "$svc" "$port" "$holder" "stop_failed" >/dev/null
            return 1
          fi
          record_port_conflict "$svc" "$port" "$holder" "stopped" >/dev/null
          log_success "port $port freed (stopped $stop_name)"
        else
          record_port_conflict "$svc" "$port" "$holder" "abort_non_docker" >/dev/null
          log_error "cannot auto-stop non-docker holder $holder"
          return 1
        fi
        ;;
      *)
        record_port_conflict "$svc" "$port" "$holder" "abort" >/dev/null
        log_error "Free port $port or set E2E_PORT_POLICY=stop-foreign"
        return 1
        ;;
    esac
  done
  return 0
}

# Canonical per-service lifecycle used by e2e + make up-serial:
#   catalog check → preflight THIS svc → compose up → verify ownership
# Returns: 0 ok (up or reuse); 1 failed
# Sets LAST_BRING_UP_STATUS=up|reuse for callers that care.
# Uses shell function `compose` when defined (e2e-staged); else docker compose.
bring_up_one_service() {
  local svc="$1"
  local pf_rc
  LAST_BRING_UP_STATUS="up"

  set +e
  preflight_service_start "$svc"
  pf_rc=$?
  set -e
  if [[ "$pf_rc" -eq 1 ]]; then
    LAST_BRING_UP_STATUS="failed"
    return 1
  fi
  if [[ "$pf_rc" -eq 2 ]]; then
    LAST_BRING_UP_STATUS="reuse"
    return 0
  fi

  log_info "compose up -d $svc"
  set +e
  if declare -F compose >/dev/null 2>&1; then
    compose up -d "$svc"
  else
    docker compose --env-file "${ENV_FILE:-.env}" up -d "$svc"
  fi
  local up_rc=$?
  set -e
  if [[ "$up_rc" -ne 0 ]]; then
    log_error "compose up failed: $svc"
    LAST_BRING_UP_STATUS="failed"
    return 1
  fi
  sleep 2
  if ! verify_service_ports_owned "$svc"; then
    LAST_BRING_UP_STATUS="failed"
    return 1
  fi
  LAST_BRING_UP_STATUS="up"
  return 0
}

# Serial bring-up of many services: preflight→up→verify per item (never bulk).
compose_up_serial() {
  local svc
  if ! assert_unique_port_catalog; then
    return 1
  fi
  for svc in "$@"; do
    log_header "Serial up: $svc"
    if ! bring_up_one_service "$svc"; then
      log_error "Stopped serial up at $svc — fix port conflict before continuing"
      return 1
    fi
    if [[ "${LAST_BRING_UP_STATUS:-up}" == "reuse" ]]; then
      log_info "reused $svc"
    else
      log_success "up+verified $svc"
    fi
  done
  return 0
}

# Before integration tests: busy ports must match the EXPECTED service container exactly.
preflight_ports_for_test() {
  local services=("$@")
  local svc ports port holder conflicts=0
  if [[ ${#services[@]} -eq 0 ]]; then
    # shellcheck disable=SC2207
    services=($(infra_all_services))
  fi
  if ! assert_unique_port_catalog; then
    return 1
  fi
  log_header "Port preflight (test mode — exact owner per service)"
  for svc in "${services[@]}"; do
    ports="$(service_host_ports "$svc")"
    for port in $ports; do
      [[ -z "$port" ]] && continue
      if ! port_listening "$port"; then
        log_info "port $port ($svc) free — service may be down"
        continue
      fi
      holder="$(port_holder_info "$port")"
      if is_exact_holder "$holder" "$(service_container_name "$svc")"; then
        log_success "port $port ($svc) OK — $holder"
      else
        log_error "port $port ($svc) WRONG owner=$holder (expected docker:$(service_container_name "$svc"))"
        record_port_conflict "$svc" "$port" "$holder" "test_abort_wrong_owner" >/dev/null
        conflicts=$((conflicts + 1))
      fi
    done
  done
  if [[ "$conflicts" -gt 0 ]]; then
    log_error "Port preflight FAILED — $conflicts wrong/foreign owner(s)."
    return 1
  fi
  log_success "Port preflight (test) passed"
  return 0
}

# Inventory for a wave of services (start mode)
preflight_wave_inventory() {
  local label="$1"
  shift
  local svc ports port holder conflicts=0
  log_info "Port inventory [$label] policy=$E2E_PORT_POLICY"
  for svc in "$@"; do
    ports="$(service_host_ports "$svc")"
    for port in $ports; do
      [[ -z "$port" ]] && continue
      if port_listening "$port"; then
        holder="$(port_holder_info "$port")"
        echo "BUSY port=$port service=$svc holder=$holder"
        conflicts=$((conflicts + 1))
      else
        echo "FREE port=$port service=$svc"
      fi
    done
  done
  log_info "Port inventory [$label] busy_entries=$conflicts"
}
