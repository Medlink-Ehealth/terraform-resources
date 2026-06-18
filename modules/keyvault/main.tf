# ─────────────────────────────────────────────────────────────────────────────
# modules/keyvault/main.tf
# MED-19c: Azure Key Vault (shared secrets store)
# Owner: Michael Olomide
#
# Provisions:
#   - Shared Key Vault (RBAC authorization model)
#   - RBAC: DevOps service principal      = Key Vault Secrets Officer (read/write)
#   - RBAC: AKS Workload Identity         = Key Vault Secrets User    (read only)
#
# Connection strings for PostgreSQL, Redis and Service Bus are written into this
# vault by their respective modules (postgres/redis/servicebus).
# ─────────────────────────────────────────────────────────────────────────────

locals {
  common_tags = {
    env          = var.environment
    app          = var.project
    region       = var.region
    managed_by   = "terraform"
    module       = "keyvault"
    costcenter   = var.cost_center
    opsteam      = var.owner
    businessunit = var.business_unit
    criticality  = var.criticality
  }
}

# ── Key Vault ─────────────────────────────────────────────────────────────────
# Uses Azure RBAC for access control (not legacy access policies). Permissions
# are therefore granted exclusively via the role assignments below.
resource "azurerm_key_vault" "main" {
  name                = var.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization  = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # false for dev — set true in prod

  tags = local.common_tags
}

# ── RBAC: DevOps service principal — read/write secrets ───────────────────────
# This is the identity Terraform runs as. Secrets Officer lets the pipeline
# create and update the connection-string secrets in this vault.
resource "azurerm_role_assignment" "devops_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.devops_principal_id
}

# ── RBAC: AKS Workload Identity — read-only secrets ───────────────────────────
# Application pods use Workload Identity to fetch secrets at runtime. Secrets
# User grants read access only — pods can never write or delete secrets.
resource "azurerm_role_assignment" "workload_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.workload_identity_principal_id
}
