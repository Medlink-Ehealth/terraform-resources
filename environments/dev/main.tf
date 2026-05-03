# ─────────────────────────────────────────────────────────────────────────────
# environments/dev/main.tf
# Entry point for the dev environment.
# Sets up the AzureRM provider and calls the network module.
# This is the file you run terraform init / plan / apply from.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110.0"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# PROVIDER
# Credentials come from terraform.tfvars — never hardcoded here.
# To switch from personal to company subscription:
#   Update subscription_id, tenant_id, client_id, client_secret
#   in terraform.tfvars and re-run terraform init + plan.
# ─────────────────────────────────────────────────────────────────────────────

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

# ─────────────────────────────────────────────────────────────────────────────
# RESOURCE GROUP
# The container that holds all dev resources in Azure.
# All modules reference this resource group by name.
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "dev" {
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

# ─────────────────────────────────────────────────────────────────────────────
# NETWORK MODULE (MED-17)
# Calls modules/network and passes in dev-specific values.
# Creates: VNet, 3 subnets, 3 NSGs, and NSG-to-subnet associations.
# depends_on ensures the resource group exists before network resources.
# ─────────────────────────────────────────────────────────────────────────────

module "network" {
  source = "../../modules/network"

  resource_group_name = azurerm_resource_group.dev.name
  location            = var.location

  vnet_name          = "medlink-vnet"
  vnet_address_space = ["10.0.0.0/16"]

  subnet_aks_name      = "aks-nodes"
  subnet_aks_cidr      = "10.0.1.0/24"
  subnet_postgres_name = "postgres-pe"
  subnet_postgres_cidr = "10.0.2.0/24"
  subnet_gateway_name  = "gateway"
  subnet_gateway_cidr  = "10.0.3.0/24"

  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  depends_on = [azurerm_resource_group.dev]
}

# ─────────────────────────────────────────────────────────────────────────────
# AKS MODULE (MED-107)
# Calls modules/aks and wires in the subnet ID from the network module output.
# The network module must be deployed first — depends_on enforces this.
# ─────────────────────────────────────────────────────────────────────────────

module "aks" {
  source = "../../modules/aks"

  # Resource placement
  resource_group_name = azurerm_resource_group.dev.name
  location            = var.location

  # Networking — wired directly from network module output.
  # No hardcoded subnet IDs anywhere.
  subnet_aks_id = module.network.subnet_aks_id

  # AKS cluster config
  cluster_name       = "medlink-dev-aks"
  kubernetes_version = "1.35.3"
  dns_prefix         = "medlink-dev"

  # System node pool (on-demand — never spot)ye
  system_node_count   = 1
  system_node_vm_size = "Standard_D2s_v4"

  # Spot user node pool with autoscaler
  spot_node_vm_size   = "Standard_D2s_v4"
  spot_node_min_count = 1
  spot_node_max_count = 3

  # Key Vault for kubeconfig storage
  key_vault_name = "medlink-kv"

  # Tags
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  depends_on = [module.network]
}
