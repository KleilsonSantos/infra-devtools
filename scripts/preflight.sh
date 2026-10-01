#!/usr/bin/env bash
# Local preflight — mirrors the CI gates that repeatedly fail before push.
# Invoked by .githooks/pre-push. Run manually: bash scripts/preflight.sh
#
# Covers (PR Validation):
#   Version SSOT + SemVer anti-drift
#   Teste 1: yamllint (compose/prometheus/alerts) + bash -n scripts/*.sh
#   Teste 3: unit tests
#   Teste 4: bandit
#
# Not covered here (need GitHub context / heavy services):
#   issue-link (see check-pr-delivery-gate.sh), Teste 6 (Postgres), remote Sonar/Snyk/GG
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

YAML_LINT_CONF='{extends: default, rules: {line-length: disable, truthy: disable, comments: disable, document-start: disable, indentation: disable, new-line-at-end-of-file: disable}}'

need_cmd() {
  local cmd="$1"
  local hint="${2:-}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "preflight: missing command '$cmd'"
    [[ -n "$hint" ]] && log_info "$hint"
    exit 1
  fi
}

log_header "Local preflight (CI parity)"

log_info "1/6 delivery-gate (issue-link parity)"
bash scripts/check-pr-delivery-gate.sh

log_info "2/6 VERSION SSOT + SemVer"
need_cmd python3 "Install Python 3.11+"
bash scripts/version.sh check
bash scripts/check-semver-alignment.sh

log_info "3/6 bash -n scripts/*.sh"
failed=0
for script in scripts/*.sh; do
  if bash -n "$script"; then
    log_debug "OK $(basename "$script")"
  else
    log_error "FAIL $(basename "$script")"
    failed=1
  fi
done
[[ "$failed" -eq 0 ]] || exit 1

log_info "4/6 yamllint (compose / prometheus / alerts)"
if command -v yamllint >/dev/null 2>&1; then
  yamllint -d "$YAML_LINT_CONF" \
    docker-compose.yml prometheus.yml alerts.yml alertmanager.yml blackbox.yml
elif python3 -c "import yamllint" 2>/dev/null; then
  python3 -m yamllint -d "$YAML_LINT_CONF" \
    docker-compose.yml prometheus.yml alerts.yml alertmanager.yml blackbox.yml
else
  log_error "preflight: missing yamllint"
  log_info "Install: pipx install yamllint  (or: python3 -m pip install yamllint)"
  exit 1
fi

log_info "5/6 pytest unit"
python3 -m pytest src/tests/unit/ -q --tb=short

log_info "6/6 bandit"
python3 -m bandit -r src/ -ll -ii >/dev/null

log_success "preflight: OK — safe to push (CI still required on GitHub)"
exit 0
