# Local Vault (Docker Compose)

Dev-only HashiCorp Vault with **file storage** and **TLS disabled**.  
Never copy this setup to production.

Compose service: `vault` → container `infra-default-vault` → host port `8200`.

## Layout

```text
vault/
├── config/vault-config.hcl   # committed (Compose mount)
└── data/                     # local persistence (gitignored except .gitkeep)
```

Secrets from init are written under `target/` (gitignored):

- `target/vault-dev-root-token.txt`
- `target/vault-dev-unseal-key.txt`

## Quick start

```bash
# 1. Ensure .env has at least:
#    VAULT_ADDR=http://127.0.0.1:8200
docker compose --env-file .env up -d vault

# 2. Init + unseal (idempotent if already unsealed)
bash scripts/vault-init-dev.sh

# 3. Use token
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=$(tr -d '[:space:]' < target/vault-dev-root-token.txt)

# 4. Optional: Database Secrets Engine → Compose postgres
docker compose --env-file .env up -d postgres
bash scripts/vault-seed-database-dev.sh
```

UI: http://127.0.0.1:8200

## After container restart

File backend seals on restart. Unseal with the saved key:

```bash
UNSEAL=$(tr -d '[:space:]' < target/vault-dev-unseal-key.txt)
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 infra-default-vault \
  vault operator unseal "$UNSEAL"
```

## Notes

- Image is pinned in `docker-compose.yml` (no `:latest`).
- `VAULT_DEV_ROOT_TOKEN_ID` in Compose is unused for `vault server -config=...` (non-`-dev` mode). Prefer init script tokens.
- Database seed is optional; core acceptance is config tree + init lifecycle.

## References

- https://developer.hashicorp.com/vault/docs/configuration
- Issue #51
- VaultSpring patterns adapted for this stack
