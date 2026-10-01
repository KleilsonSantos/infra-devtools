#!/usr/bin/env bash
# Initialize and unseal local Vault (Compose file backend). Run once per fresh volume.
# Writes root token to target/vault-dev-root-token.txt (gitignored).
#
# Usage:
#   docker compose --env-file .env up -d vault
#   bash scripts/vault-init-dev.sh
#   export VAULT_TOKEN=$(cat target/vault-dev-root-token.txt)
#   bash scripts/vault-seed-database-dev.sh   # optional
#
# See docs/guides/vault-local.md
set -euo pipefail

: "${VAULT_ADDR:=http://127.0.0.1:8200}"
CONTAINER="${VAULT_CONTAINER:-infra-default-vault}"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "Container $CONTAINER is not running. Start with: docker compose --env-file .env up -d vault"
  exit 1
fi

# Volume mounts may leave /vault/data owned by root — fix before first init.
docker exec -u 0 "$CONTAINER" sh -c "chown -R vault:vault /vault/data 2>/dev/null || true" >/dev/null 2>&1 || true

HEALTH=$(curl -sf "$VAULT_ADDR/v1/sys/health" || curl -s "$VAULT_ADDR/v1/sys/health" || true)
if [ -z "$HEALTH" ]; then
  echo "Vault not reachable at $VAULT_ADDR"
  exit 1
fi

if echo "$HEALTH" | grep -q '"initialized":true'; then
  if echo "$HEALTH" | grep -q '"sealed":false'; then
    echo "Vault already initialized and unsealed."
    exit 0
  fi
  echo "Vault initialized but sealed — unseal manually with your unseal key."
  exit 1
fi

INIT_JSON=$(docker exec -e VAULT_ADDR='http://127.0.0.1:8200' "$CONTAINER" \
  vault operator init -key-shares=1 -key-threshold=1 -format=json)

UNSEAL_KEY=$(echo "$INIT_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['unseal_keys_b64'][0])")
ROOT_TOKEN=$(echo "$INIT_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['root_token'])")

docker exec -e VAULT_ADDR='http://127.0.0.1:8200' "$CONTAINER" vault operator unseal "$UNSEAL_KEY" >/dev/null

mkdir -p target
printf '%s\n' "$UNSEAL_KEY" > target/vault-dev-unseal-key.txt
printf '%s\n' "$ROOT_TOKEN" > target/vault-dev-root-token.txt
chmod 600 target/vault-dev-unseal-key.txt target/vault-dev-root-token.txt

echo "Vault initialized and unsealed."
echo "Root token → target/vault-dev-root-token.txt (never commit)."
echo "Unseal key → target/vault-dev-unseal-key.txt (never commit; needed after restart)."
echo "Next: export VAULT_TOKEN=\$(tr -d '[:space:]' < target/vault-dev-root-token.txt)"
echo "Optional: bash scripts/vault-seed-database-dev.sh"
