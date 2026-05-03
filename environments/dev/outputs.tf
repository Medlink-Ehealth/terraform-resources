# ─────────────────────────────────────────────────────────────────────────────
# environments/dev/outputs.tf
# Printed to terminal after terraform apply.
# Also used by future modules (AKS, Postgres) to reference network resources.
# ─────────────────────────────────────────────────────────────────────────────

output "resource_group_name" {
  description = "Name of the dev resource group."
  value       = azurerm_resource_group.dev.name
}

output "vnet_id" {
  description = "Resource ID of the dev VNet."
  value       = module.network.vnet_id
}

output "vnet_name" {
  description = "Name of the dev VNet."
  value       = module.network.vnet_name
}

output "subnet_aks_id" {
  description = "AKS subnet ID — pass to the AKS module (MED-18)."
  value       = module.network.subnet_aks_id
}

output "subnet_postgres_id" {
  description = "Postgres subnet ID — pass to the postgres module."
  value       = module.network.subnet_postgres_id
}

output "subnet_gateway_id" {
  description = "Gateway subnet ID — used when Front Door is added."
  value       = module.network.subnet_gateway_id
}

output "aks_cluster_name" {
  description = "AKS cluster name — use this to get credentials."
  value       = module.aks.cluster_name
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for Workload Identity setup."
  value       = module.aks.oidc_issuer_url
}

output "key_vault_uri" {
  description = "Key Vault URI — where the kubeconfig secret is stored."
  value       = module.aks.key_vault_uri
}

output "kubeconfig_secret_name" {
  description = "Key Vault secret name holding the kubeconfig."
  value       = module.aks.kubeconfig_secret_name
}
