# ─────────────────────────────────────────────────────────────────────────────
# modules/servicebus/main.tf
# MED-19b: Azure Service Bus (Standard)
# Owner: Michael Olomide
#
# Provisions:
#   - Service Bus namespace (Standard SKU — required for topics)
#   - Topics: appointments, prescriptions, notifications
#   - One subscription per topic
#   - Namespace connection string stored in the shared Key Vault
# ─────────────────────────────────────────────────────────────────────────────

locals {
  common_tags = {
    env          = var.environment
    app          = var.project
    region       = var.region
    managed_by   = "terraform"
    module       = "servicebus"
    costcenter   = var.cost_center
    opsteam      = var.owner
    businessunit = var.business_unit
    criticality  = var.criticality
  }
}

# ── Namespace ─────────────────────────────────────────────────────────────────
# Standard SKU is the minimum tier that supports topics and subscriptions.
resource "azurerm_servicebus_namespace" "main" {
  name                = var.servicebus_namespace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku

  tags = local.common_tags
}

# ── Topics ────────────────────────────────────────────────────────────────────
# One topic per domain event stream: appointments, prescriptions, notifications.
resource "azurerm_servicebus_topic" "topics" {
  for_each = toset(var.topics)

  name         = each.value
  namespace_id = azurerm_servicebus_namespace.main.id
}

# ── Subscriptions ─────────────────────────────────────────────────────────────
# Each topic gets a default subscription so consumers have somewhere to read.
resource "azurerm_servicebus_subscription" "subscriptions" {
  for_each = azurerm_servicebus_topic.topics

  name               = "${each.value.name}-sub"
  topic_id           = each.value.id
  max_delivery_count = 10
}

# ── Connection string in Key Vault ────────────────────────────────────────────
resource "azurerm_key_vault_secret" "connection_string" {
  name         = "servicebus-connection-string"
  key_vault_id = var.key_vault_id
  value        = azurerm_servicebus_namespace.main.default_primary_connection_string

  tags = local.common_tags
}
