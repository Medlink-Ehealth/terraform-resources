# ─────────────────────────────────────────────────────────────────────────────
# modules/keyvault/outputs.tf
# ─────────────────────────────────────────────────────────────────────────────

output "key_vault_id" {
  description = "Resource ID of the Key Vault."
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault — used by apps to fetch secrets."
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_name" {
  description = "Name of the Key Vault."
  value       = azurerm_key_vault.main.name
}
