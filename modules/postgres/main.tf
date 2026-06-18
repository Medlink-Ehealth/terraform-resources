# ─────────────────────────────────────────────────────────────────────────────
# modules/postgres/main.tf
# MED-19a: PostgreSQL Flexible Server (Burstable B1ms)
# Owner: Michael Olomide
#
# Provisions:
#   - PostgreSQL Flexible Server with VNet integration (no public access)
#   - Private DNS zone + VNet link so the FQDN resolves inside the VNet only
#   - An application database
#   - Connection string stored in the shared Key Vault
# ─────────────────────────────────────────────────────────────────────────────

locals {
  common_tags = {
    env          = var.environment
    app          = var.project
    region       = var.region
    managed_by   = "terraform"
    module       = "postgres"
    costcenter   = var.cost_center
    opsteam      = var.owner
    businessunit = var.business_unit
    criticality  = var.criticality
  }

  # Use the supplied admin password if provided, otherwise fall back to the
  # randomly generated one. The generated password never leaves Key Vault.
  admin_password = var.admin_password != null ? var.admin_password : random_password.admin.result
}

# ── Auto-generated admin password ─────────────────────────────────────────────
# Generated when no password is supplied, so no human ever handles the secret.
# Restricted to URL-safe symbols so it can be embedded in the connection string
# without percent-encoding.
resource "random_password" "admin" {
  length           = 32
  special          = true
  override_special = "_-"

  # Guarantee Azure's password complexity requirement (3 of 4 categories).
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

# ── Private DNS zone ──────────────────────────────────────────────────────────
# Flexible Server VNet integration requires a private DNS zone whose name ends
# in .private.postgres.database.azure.com. The server FQDN resolves to a private
# IP through this zone — only resolvable from inside the linked VNet.
resource "azurerm_private_dns_zone" "postgres" {
  name                = "medlink${var.environment}.private.postgres.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "pdnsz-link-psql-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false

  tags = local.common_tags
}

# ── PostgreSQL Flexible Server ────────────────────────────────────────────────
# delegated_subnet_id + private_dns_zone_id put the server inside the VNet with
# no public endpoint. public_network_access is implicitly disabled in this mode.
resource "azurerm_postgresql_flexible_server" "main" {
  name                = var.postgres_server_name
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.postgres_version

  administrator_login    = var.admin_username
  administrator_password = local.admin_password

  sku_name   = var.sku_name
  storage_mb = var.storage_mb

  delegated_subnet_id = var.subnet_postgres_id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  # The VNet link must exist before the server is created, otherwise the server
  # cannot register its private DNS record.
  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]

  tags = local.common_tags
}

# ── Application database ──────────────────────────────────────────────────────
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# ── Connection string in Key Vault ────────────────────────────────────────────
# sslmode=require enforces TLS for every connection.
resource "azurerm_key_vault_secret" "connection_string" {
  name         = "postgres-connection-string"
  key_vault_id = var.key_vault_id
  value = format(
    "postgresql://%s:%s@%s:5432/%s?sslmode=require",
    var.admin_username,
    local.admin_password,
    azurerm_postgresql_flexible_server.main.fqdn,
    azurerm_postgresql_flexible_server_database.main.name,
  )

  tags = local.common_tags
}
