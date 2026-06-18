# ─────────────────────────────────────────────────────────────────────────────
# modules/redis/outputs.tf
# ─────────────────────────────────────────────────────────────────────────────

output "redis_id" {
  description = "Resource ID of the Managed Redis instance."
  value       = azurerm_managed_redis.main.id
}

output "redis_hostname" {
  description = "Hostname of the Managed Redis instance."
  value       = azurerm_managed_redis.main.hostname
}

output "redis_ssl_port" {
  description = "TLS port for rediss:// connections."
  value       = azurerm_managed_redis.main.default_database[0].port
}

output "redis_connection_string_secret_name" {
  description = "Key Vault secret name holding the connection string."
  value       = azurerm_key_vault_secret.connection_string.name
}
