# ─────────────────────────────────────────────────────────────────────────────
# modules/redis/main.tf
# MED-19a: Azure Managed Redis (Balanced_B0, TLS enforced)
# Owner: Michael Olomide
#
# Azure Cache for Redis (Basic/Standard) is retired for new deployments, so this
# uses Azure Managed Redis — its successor — at the smallest Balanced_B0 SKU.
#
# Provisions:
#   - Azure Managed Redis instance (Balanced_B0)
#   - default database with TLS-only access (client_protocol = Encrypted)
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

# ── Managed Redis ─────────────────────────────────────────────────────────────
# client_protocol = "Encrypted" forces every client to connect over TLS, so the
# connection string uses the rediss:// scheme. access_keys_authentication_enabled
# must be true for the primary access key (used in the connection string) to be
# exported by the provider.
resource "azurerm_managed_redis" "main" {
  name                = var.redis_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name

  # High availability disabled for dev to keep costs down. Changing this forces
  # a new instance — set true in prod for zone-redundant replicas.
  high_availability_enabled = var.high_availability_enabled

  default_database {
    client_protocol                    = "Encrypted"
    access_keys_authentication_enabled = true
  }

  tags = local.common_tags
}

# ── Connection string in Key Vault ────────────────────────────────────────────
# rediss:// scheme enforces TLS on every client connection.
resource "azurerm_key_vault_secret" "connection_string" {
  name         = "redis-connection-string"
  key_vault_id = var.key_vault_id
  value = format(
    "rediss://:%s@%s:%d",
    azurerm_managed_redis.main.default_database[0].primary_access_key,
    azurerm_managed_redis.main.hostname,
    azurerm_managed_redis.main.default_database[0].port,
  )

  tags = local.common_tags
}
