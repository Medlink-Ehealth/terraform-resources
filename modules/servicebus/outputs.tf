# ─────────────────────────────────────────────────────────────────────────────
# modules/servicebus/outputs.tf
# ─────────────────────────────────────────────────────────────────────────────

output "servicebus_namespace_id" {
  description = "Resource ID of the Service Bus namespace."
  value       = azurerm_servicebus_namespace.main.id
}

output "servicebus_endpoint" {
  description = "Service Bus endpoint URL."
  value       = azurerm_servicebus_namespace.main.endpoint
}

output "servicebus_topic_names" {
  description = "Names of the Service Bus topics created."
  value       = [for t in azurerm_servicebus_topic.topics : t.name]
}

output "servicebus_connection_string_secret_name" {
  description = "Key Vault secret name holding the connection string."
  value       = azurerm_key_vault_secret.connection_string.name
}
