#!/usr/bin/env bash
# Serial compose up: for EACH service → preflight ports → up → verify exact owner → next.
# Never bulk-starts the whole stack in one shot (avoids masked port conflicts).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
# shellcheck source=lib-port-preflight.sh
. "$(dirname "$0")/lib-port-preflight.sh"

ENV_FILE="${ENV_FILE:-.env}"
E2E_PORT_POLICY="${E2E_PORT_POLICY:-abort}"
export ENV_FILE E2E_PORT_POLICY

SERVICES=("$@")
if [[ ${#SERVICES[@]} -eq 0 ]]; then
  # shellcheck disable=SC2207
  SERVICES=($(infra_all_services))
fi

log_header "compose-up-serial ($((${#SERVICES[@]})) services) policy=$E2E_PORT_POLICY"
compose_up_serial "${SERVICES[@]}"
log_success "Serial compose up finished"
