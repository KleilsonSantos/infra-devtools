#!/usr/bin/env bash
# Configure Vault Database Secrets Engine for local PostgreSQL (Compose).
# Requires unsealed Vault, VAULT_TOKEN, and running postgres service.
#
# Usage:
#   set -a && source .env && set +a
#   export VAULT_ADDR=http://127.0.0.1:8200
#   export VAULT_TOKEN=$(tr -d '[:space:]' < target/vault-dev-root-token.txt)
#   bash scripts/vault-seed-database-dev.sh
#
# Optional overrides: POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, VAULT_DB_ROLE
set -euo pipefail

: "${VAULT_ADDR:?Set VAULT_ADDR (e.g. http://127.0.0.1:8200)}"
: "${VAULT_TOKEN:?Set VAULT_TOKEN — never commit this value}"

POSTGRES_DB="${POSTGRES_DB:-postgres}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
VAULT_DB_ROLE="${VAULT_DB_ROLE:-infra-devtools-app}"
VAULT_DB_CONFIG="${VAULT_DB_CONFIG:-infra-postgresql}"
CONTAINER="${VAULT_CONTAINER:-infra-default-vault}"

run_vault() {
  if command -v vault >/dev/null 2>&1; then
    vault "$@"
  else
    docker exec -e VAULT_ADDR='http://127.0.0.1:8200' -e VAULT_TOKEN="$VAULT_TOKEN" "$CONTAINER" vault "$@"
  fi
}

run_vault secrets enable database 2>/dev/null || true

run_vault write "database/config/${VAULT_DB_CONFIG}" \
  plugin_name=postgresql-database-plugin \
  allowed_roles="${VAULT_DB_ROLE}" \
  connection_url="postgresql://{{username}}:{{password}}@postgres:5432/${POSTGRES_DB}?sslmode=disable" \
  username="${POSTGRES_USER}" \
  password="${POSTGRES_PASSWORD}"

run_vault write "database/roles/${VAULT_DB_ROLE}" \
  db_name="${VAULT_DB_CONFIG}" \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"

echo "Database secrets engine configured (role: ${VAULT_DB_ROLE}, config: ${VAULT_DB_CONFIG})"
echo "Read dynamic creds: vault read database/creds/${VAULT_DB_ROLE}"
