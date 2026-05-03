# ─────────────────────────────────────────────────────────────────────────────
# modules/network/outputs.tf
# Exports resource IDs so other modules (aks, postgres) can reference
# the network without hardcoding any IDs.
# ─────────────────────────────────────────────────────────────────────────────

output "vnet_id" {
  description = "Resource ID of the Virtual Network."
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the Virtual Network."
  value       = azurerm_virtual_network.main.name
}

output "subnet_aks_id" {
  description = "Subnet ID for AKS nodes — pass this to the AKS module (MED-18)."
  value       = azurerm_subnet.aks_nodes.id
}

output "subnet_aks_cidr" {
  description = "CIDR block of the AKS nodes subnet."
  value       = var.subnet_aks_cidr
}

output "subnet_postgres_id" {
  description = "Subnet ID for PostgreSQL private endpoint."
  value       = azurerm_subnet.postgres_pe.id
}

output "subnet_gateway_id" {
  description = "Subnet ID for the gateway — used when Front Door is added."
  value       = azurerm_subnet.gateway.id
}

output "nsg_aks_id" {
  description = "Resource ID of the AKS nodes NSG."
  value       = azurerm_network_security_group.aks_nodes.id
}

output "nsg_postgres_id" {
  description = "Resource ID of the PostgreSQL NSG."
  value       = azurerm_network_security_group.postgres_pe.id
}
