# ─────────────────────────────────────────────────────────────────────────────
# environments/prod.tfvars
# Production environment values — larger nodes, higher availability.
# ─────────────────────────────────────────────────────────────────────────────

environment         = "prod"
location            = "australiaeast"
resource_group_name = "medlink-prod-rg"
owner               = "samsontunj@gmail.com"
project             = "medlink"
cost_center         = "medlink-engineering"

# Networking — different CIDR to avoid overlap with dev
vnet_address_space   = ["10.1.0.0/16"]
subnet_aks_cidr      = "10.1.1.0/24"
subnet_postgres_cidr = "10.1.2.0/24"
subnet_gateway_cidr  = "10.1.3.0/24"

# AKS — larger nodes, more replicas for prod
kubernetes_version  = "1.35.3"
system_node_vm_size = "Standard_D4s_v4"
spot_node_vm_size   = "Standard_D4s_v4"
spot_node_min_count = 2
spot_node_max_count = 10
key_vault_name      = "medlink-kv"

# Front Door
nginx_ingress_ip = "PROD_NGINX_IP_HERE"
waf_mode         = "Prevention"

# Storage
storage_account_name = "stmedlinkprod001"

# CAF Tags
region        = "australiaeast"
business_unit = "engineering"
criticality   = "mission-critical"
