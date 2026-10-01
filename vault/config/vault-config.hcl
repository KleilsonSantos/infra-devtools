# Local Vault server (Docker Compose). TLS is disabled on purpose for
# loopback development only — never use this file as-is in production.
# Official listener/storage blocks:
# https://developer.hashicorp.com/vault/docs/configuration
#
# Mounted by docker-compose as /vault/config/vault-config.hcl

ui = true
disable_mlock = true

storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

api_addr     = "http://0.0.0.0:8200"
cluster_addr = "http://0.0.0.0:8201"
