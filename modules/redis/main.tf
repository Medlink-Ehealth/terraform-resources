# ─────────────────────────────────────────────────────────────────────────────
# modules/redis/main.tf
# MED-19a: Azure Cache for Redis (Basic C0, TLS enforced)
# Owner: Michael Olomide
#
# Provisions:
#   - Azure Cache for Redis (Basic C0)
#   - TLS enforced — the non-SSL (6379) port is disabled, minimum TLS 1.2
#   - rediss:// connection string stored in the shared Key Vault
# ─────────────────────────────────────────────────────────────────────────────

locals {
  common_tags = {
    env          = var.environment
    app          = var.project
    region       = var.region
    managed_by   = "terraform"
    module       = "redis"
    costcenter   = var.cost_center
    opsteam      = var.owner
    businessunit = var.business_unit
    criticality  = var.criticality
  }
}

# ── Redis cache ───────────────────────────────────────────────────────────────
# enable_non_ssl_port = false closes the plaintext 6379 port, so clients must
# connect over TLS via the 6380 SSL port (rediss://).
resource "azurerm_redis_cache" "main" {
  name                = var.redis_name
  location            = var.location
  resource_group_name = var.resource_group_name

  capacity = var.capacity
  family   = var.family
  sku_name = var.sku_name

  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  tags = local.common_tags
}

# ── Connection string in Key Vault ────────────────────────────────────────────
# rediss:// scheme + the SSL port enforce TLS on every client connection.
resource "azurerm_key_vault_secret" "connection_string" {
  name         = "redis-connection-string"
  key_vault_id = var.key_vault_id
  value = format(
    "rediss://:%s@%s:%d",
    azurerm_redis_cache.main.primary_access_key,
    azurerm_redis_cache.main.hostname,
    azurerm_redis_cache.main.ssl_port,
  )

  tags = local.common_tags
}
