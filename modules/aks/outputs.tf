# ─────────────────────────────────────────────────────────────────────────────
# modules/aks/outputs.tf
# Exports values other modules and the environment layer need.
# Most importantly: the OIDC issuer URL (needed for Workload Identity)
# and the cluster identity (needed to assign ACR pull permissions).
# ─────────────────────────────────────────────────────────────────────────────

output "cluster_id" {
  description = "Resource ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "Name of the AKS cluster — use this to run az aks get-credentials."
  value       = azurerm_kubernetes_cluster.main.name
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL — needed to configure Workload Identity federated credentials."
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet managed identity — used to assign AcrPull role."
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "cluster_identity_principal_id" {
  description = "Principal ID of the AKS system-assigned identity — used for role assignments."
  value       = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault created for this cluster."
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault — used by apps to fetch secrets."
  value       = azurerm_key_vault.main.vault_uri
}

# output "kubeconfig_secret_name" {
#   description = "Name of the Key Vault secret holding the kubeconfig."
#   value       = azurerm_key_vault_secret.kubeconfig.name
# }
