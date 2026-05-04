# ─────────────────────────────────────────────────────────────────────────────
# main.tf
# Root module — creates the resource group and calls all child modules.
# Run with:
#   terraform plan -var-file=environments/dev.tfvars
#   terraform apply -var-file=environments/dev.tfvars
# ─────────────────────────────────────────────────────────────────────────────

# ── Resource Group ────────────────────────────────────────────────────────────
# The container that holds all resources for this environment.
# All modules reference this resource group by name.

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = var.environment
    project     = var.project
    owner       = var.owner
    cost_center = var.cost_center
    managed_by  = "terraform"
  }
}

# ── Network Module (MED-17) ───────────────────────────────────────────────────
# Creates VNet, 3 subnets, 3 NSGs and NSG-to-subnet associations.
# Outputs subnet IDs consumed by the AKS module below.

module "network" {
  source = "./modules/network"

  resource_group_name  = azurerm_resource_group.main.name
  location             = var.location
  vnet_name            = "medlink-vnet"
  vnet_address_space   = var.vnet_address_space
  subnet_aks_name      = "aks-nodes"
  subnet_aks_cidr      = var.subnet_aks_cidr
  subnet_postgres_name = "postgres-pe"
  subnet_postgres_cidr = var.subnet_postgres_cidr
  subnet_gateway_name  = "gateway"
  subnet_gateway_cidr  = var.subnet_gateway_cidr
  environment          = var.environment
  project              = var.project
  owner                = var.owner
  cost_center          = var.cost_center

  depends_on = [azurerm_resource_group.main]
}

# ── AKS Module (MED-107) ──────────────────────────────────────────────────────
# Creates AKS cluster with system + spot node pools, Key Vault,
# and stores kubeconfig in Key Vault.
# subnet_aks_id is wired from network module output — no hardcoding.

module "aks" {
  source = "./modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  subnet_aks_id       = module.network.subnet_aks_id
  cluster_name        = "medlink-${var.environment}-aks"
  kubernetes_version  = var.kubernetes_version
  dns_prefix          = "medlink-${var.environment}"
  system_node_count   = 1
  system_node_vm_size = var.system_node_vm_size
  spot_node_vm_size   = var.spot_node_vm_size
  spot_node_min_count = var.spot_node_min_count
  spot_node_max_count = var.spot_node_max_count
  key_vault_name      = var.key_vault_name
  environment         = var.environment
  project             = var.project
  owner               = var.owner
  cost_center         = var.cost_center

  depends_on = [module.network]
}
