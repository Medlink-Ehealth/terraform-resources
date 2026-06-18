# ─────────────────────────────────────────────────────────────────────────────
# environments/dev.tfvars
# Dev environment values.
# Used with: terraform plan -var-file=environments/dev.tfvars
#
# ⚠️  No credentials here — those come from environment variables
#     or GitHub Secrets in the pipeline.
# ─────────────────────────────────────────────────────────────────────────────

environment         = "dev"
location            = "australiaeast"
resource_group_name = "medlink-dev-rg"
owner               = "samsontunj@gmail.com"
project             = "medlink"
cost_center         = "medlink-engineering"

# Networking
vnet_address_space   = ["10.0.0.0/16"]
subnet_aks_cidr      = "10.0.1.0/24"
subnet_postgres_cidr = "10.0.2.0/24"
subnet_gateway_cidr  = "10.0.3.0/24"

# CAF Tags
region        = "australiaeast"
business_unit = "engineering"
criticality   = "low"

# AKS
kubernetes_version  = "1.35.3"
system_node_vm_size = "Standard_D2s_v4"
spot_node_vm_size   = "Standard_D2s_v4"
spot_node_min_count = 1
spot_node_max_count = 3
key_vault_name      = "medlink-kv"

# Front Door
nginx_ingress_ip = "20.167.106.121"
waf_mode         = "Detection"

# Storage
storage_account_name = "stmedlink001"
