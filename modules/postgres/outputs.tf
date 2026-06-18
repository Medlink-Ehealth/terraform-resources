# ─────────────────────────────────────────────────────────────────────────────
# modules/postgres/outputs.tf
# ─────────────────────────────────────────────────────────────────────────────

output "postgres_server_id" {
  description = "Resource ID of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.main.id
}

output "postgres_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL server."
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgres_database_name" {
  description = "Name of the application database."
  value       = azurerm_postgresql_flexible_server_database.main.name
}

output "postgres_connection_string_secret_name" {
  description = "Key Vault secret name holding the connection string."
  value       = azurerm_key_vault_secret.connection_string.name
}
