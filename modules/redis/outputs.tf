# ─────────────────────────────────────────────────────────────────────────────
# modules/redis/outputs.tf
# ─────────────────────────────────────────────────────────────────────────────

output "redis_id" {
  description = "Resource ID of the Redis cache."
  value       = azurerm_redis_cache.main.id
}

output "redis_hostname" {
  description = "Hostname of the Redis cache."
  value       = azurerm_redis_cache.main.hostname
}

output "redis_ssl_port" {
  description = "SSL port for TLS connections (rediss://)."
  value       = azurerm_redis_cache.main.ssl_port
}

output "redis_connection_string_secret_name" {
  description = "Key Vault secret name holding the connection string."
  value       = azurerm_key_vault_secret.connection_string.name
}
