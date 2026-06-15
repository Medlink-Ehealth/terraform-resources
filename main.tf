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
    env          = var.environment
    app          = var.project
    region       = var.region
    managed_by   = "terraform"
    costcenter   = var.cost_center
    opsteam      = var.owner
    businessunit = var.business_unit
    criticality  = var.criticality
  }
}

# ── Network Module (MED-17) ───────────────────────────────────────────────────
# Creates VNet, 3 subnets, 3 NSGs and NSG-to-subnet associations.
# Outputs subnet IDs consumed by the AKS module below.

module "network" {
  source = "./modules/network"

  resource_group_name  = azurerm_resource_group.main.name
  location             = var.location
  vnet_name            = "vnet-medlink-aue-001"
  vnet_address_space   = var.vnet_address_space
  subnet_aks_name      = "snet-aks-aue-001"
  subnet_aks_cidr      = var.subnet_aks_cidr
  subnet_postgres_name = "snet-psql-aue-001"
  subnet_postgres_cidr = var.subnet_postgres_cidr
  subnet_gateway_name  = "snet-gw-aue-001"
  subnet_gateway_cidr  = var.subnet_gateway_cidr
  environment          = var.environment
  project              = var.project
  owner                = var.owner
  cost_center          = var.cost_center
  region               = var.region
  business_unit        = var.business_unit
  criticality          = var.criticality

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
  cluster_name        = "aks-medlink-${var.environment}"
  kubernetes_version  = var.kubernetes_version
  dns_prefix          = "medlink-${var.environment}"
  system_node_count   = 1
  system_node_vm_size = var.system_node_vm_size
  spot_node_vm_size   = var.spot_node_vm_size
  spot_node_min_count = var.spot_node_min_count
  spot_node_max_count = var.spot_node_max_count
  key_vault_name      = "kv-medlink-${var.environment}"
  environment         = var.environment
  project             = var.project
  owner               = var.owner
  cost_center         = var.cost_center
  region              = var.region
  business_unit       = var.business_unit
  criticality         = var.criticality

  depends_on = [module.network]
}


# ── Front Door Module (MED-105) ───────────────────────────────────────────────
# Creates Front Door Standard profile, WAF policy, endpoint, origin group,
# origin pointing to NGINX Ingress IP, route, and security policy.
# Depends on AKS being deployed first so the NGINX IP exists.

module "frontdoor" {
  source = "./modules/frontdoor"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  frontdoor_name      = "afd-medlink-${var.environment}"
  origin_ip           = var.nginx_ingress_ip
  waf_policy_name     = "fdfpmedlink${var.environment}"
  waf_mode            = var.waf_mode
  environment         = var.environment
  project             = var.project
  owner               = var.owner
  cost_center         = var.cost_center
  region              = var.region
  business_unit       = var.business_unit
  criticality         = var.criticality

  depends_on = [module.aks]
}

# ── Storage Module (MED-118) ──────────────────────────────────────────────────
# Creates storage account with three containers: documents, pdfs, tfstate.
# Configures soft-delete (7 days), versioning on tfstate,
# and lifecycle policy (Cool after 90 days, Archive after 365 days).

module "storage" {
  source = "./modules/storage"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  storage_account_name       = var.storage_account_name
  account_tier               = "Standard"
  account_replication_type   = "LRS"
  soft_delete_retention_days = 7
  cool_tier_after_days       = 90
  archive_tier_after_days    = 365
  environment                = var.environment
  project                    = var.project
  owner                      = var.owner
  cost_center                = var.cost_center
  region                     = var.region
  business_unit              = var.business_unit
  criticality                = var.criticality

  depends_on = [azurerm_resource_group.main]
}

# ── ACR Module (MED-19) ───────────────────────────────────────────────────────
# Creates a new Azure Container Registry in the workload region (same RG as
# AKS) and grants the AKS kubelet managed identity AcrPull on it so the
# cluster can pull images without credentials.

module "acr" {
  source = "./modules/acr"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  acr_name                   = var.acr_name
  sku                        = var.acr_sku
  kubelet_identity_object_id = module.aks.kubelet_identity_object_id
  environment                = var.environment
  project                    = var.project
  owner                      = var.owner
  cost_center                = var.cost_center
  region                     = var.region
  business_unit              = var.business_unit
  criticality                = var.criticality

  depends_on = [module.aks]
}
