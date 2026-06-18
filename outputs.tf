# ─────────────────────────────────────────────────────────────────────────────
# outputs.tf
# Values printed to terminal after terraform apply.
# Also consumed by other pipelines or modules that need these IDs.
# ─────────────────────────────────────────────────────────────────────────────

output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "VNet resource ID."
  value       = module.network.vnet_id
}

output "vnet_name" {
  description = "VNet name."
  value       = module.network.vnet_name
}

output "subnet_aks_id" {
  description = "AKS subnet ID — consumed by AKS module."
  value       = module.network.subnet_aks_id
}

output "subnet_postgres_id" {
  description = "PostgreSQL private endpoint subnet ID."
  value       = module.network.subnet_postgres_id
}

output "aks_cluster_name" {
  description = "AKS cluster name — use with az aks get-credentials."
  value       = module.aks.cluster_name
}

output "oidc_issuer_url" {
  description = "AKS OIDC issuer URL — needed for Workload Identity."
  value       = module.aks.oidc_issuer_url
}

# output "key_vault_uri" {
#   description = "Key Vault URI — where kubeconfig secret is stored."
#   value       = module.aks.key_vault_uri
# }


output "frontdoor_hostname" {
  description = "Front Door public hostname — open this in a browser to test."
  value       = module.frontdoor.frontdoor_endpoint_hostname
}

output "storage_account_name" {
  description = "Storage account name."
  value       = module.storage.storage_account_name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL."
  value       = module.storage.primary_blob_endpoint
}

output "acr_login_server" {
  description = "Login server URL of the ACR created by this stack."
  value       = module.acr.acr_login_server
}

output "acr_id" {
  description = "Resource ID of the ACR created by this stack."
  value       = module.acr.acr_id
}

# ── MED-19: Platform data services ────────────────────────────────────────────

output "shared_key_vault_uri" {
  description = "URI of the shared Key Vault holding all connection strings."
  value       = module.keyvault.key_vault_uri
}

output "shared_key_vault_name" {
  description = "Name of the shared Key Vault."
  value       = module.keyvault.key_vault_name
}

output "workload_identity_client_id" {
  description = "Client ID of the app Workload Identity — used to configure federated credentials."
  value       = azurerm_user_assigned_identity.workload.client_id
}

output "postgres_fqdn" {
  description = "Private FQDN of the PostgreSQL Flexible Server."
  value       = module.postgres.postgres_fqdn
}

output "redis_hostname" {
  description = "Hostname of the Redis cache."
  value       = module.redis.redis_hostname
}

output "servicebus_endpoint" {
  description = "Service Bus namespace endpoint."
  value       = module.servicebus.servicebus_endpoint
}

output "servicebus_topic_names" {
  description = "Service Bus topics created."
  value       = module.servicebus.servicebus_topic_names
}
