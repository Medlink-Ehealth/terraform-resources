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
