#!/usr/bin/env bash
# CLI wrapper for lib-port-preflight.sh — used by Makefile, run-tests.sh, CI hooks.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
# shellcheck source=lib-port-preflight.sh
. "$(dirname "$0")/lib-port-preflight.sh"

MODE="test"
SERVICES=()
POLICY="${E2E_PORT_POLICY:-abort}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --services)
      IFS=',' read -r -a SERVICES <<<"$2"
      shift 2
      ;;
    --policy) POLICY="$2"; E2E_PORT_POLICY="$2"; shift 2 ;;
    --log) PORT_CONFLICTS_LOG="$2"; shift 2 ;;
    -h|--help)
      cat <<'EOF'
Usage:
  bash scripts/check-port-conflicts.sh --mode test
  bash scripts/check-port-conflicts.sh --mode start [--services redis,postgres]
  bash scripts/check-port-conflicts.sh --mode catalog
  bash scripts/check-port-conflicts.sh --mode start --policy stop-foreign

Modes:
  catalog  Fail if docker-compose.yml maps the same HOST port to two services
  test     Fail if any mapped host port has the wrong owner (not infra-default-<svc>)
  start    Preflight before compose up (reuse ours; abort/stop foreign)
  serial-up  Serial compose up with per-service gate

Rule (Docker Compose): one HOST_PORT → one service. Container ports may coincide
across services; host publish ports must not. See Docker networking docs.
EOF
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

E2E_PORT_POLICY="$POLICY"
export E2E_PORT_POLICY PORT_CONFLICTS_LOG

case "$MODE" in
  catalog)
    assert_unique_port_catalog
    ;;
  test)
    if [[ ${#SERVICES[@]} -gt 0 ]]; then
      preflight_ports_for_test "${SERVICES[@]}"
    else
      preflight_ports_for_test
    fi
    ;;
  start)
    if [[ ${#SERVICES[@]} -eq 0 ]]; then
      # shellcheck disable=SC2207
      SERVICES=($(infra_all_services))
    fi
    # Per-service gate only (does not compose up — caller does up after)
    assert_unique_port_catalog
    preflight_wave_inventory "start" "${SERVICES[@]}"
    blocked=0
    for svc in "${SERVICES[@]}"; do
      set +e
      preflight_service_start "$svc"
      rc=$?
      set -e
      if [[ "$rc" -eq 1 ]]; then
        blocked=1
      fi
    done
    [[ "$blocked" -eq 0 ]] || exit 1
    log_success "Port preflight (start) passed for ${#SERVICES[@]} service(s)"
    ;;
  serial-up)
    if [[ ${#SERVICES[@]} -eq 0 ]]; then
      # shellcheck disable=SC2207
      SERVICES=($(infra_all_services))
    fi
    compose_up_serial "${SERVICES[@]}"
    ;;
  *)
    log_error "Unknown mode: $MODE"
    exit 2
    ;;
esac
