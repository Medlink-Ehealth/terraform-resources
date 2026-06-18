# ─────────────────────────────────────────────────────────────────────────────
# modules/aks/main.tf
# MED-107: Provision AKS Cluster — System + Spot User Node Pools
#
# What this file creates:
#   1. Azure Key Vault       — stores the kubeconfig secret securely
#   2. AKS Cluster           — the Kubernetes control plane
#   3. System node pool      — runs Kubernetes system pods (on-demand VMs)
#   4. Spot user node pool   — runs your app workloads (cheap spot VMs)
#   5. Cluster Autoscaler    — automatically scales the spot pool min 1 / max 3
#   6. Workload Identity     — lets pods authenticate to Azure without passwords
#   7. OIDC Issuer           — required for Workload Identity to work
#   8. kubeconfig secret     — stored in Key Vault so the whole team can access
# ─────────────────────────────────────────────────────────────────────────────

# ── Data sources ──────────────────────────────────────────────────────────────
# We look up the current Azure subscription and client details at runtime.
# This avoids hardcoding tenant and subscription IDs in the module.

data "azurerm_client_config" "current" {}

# ── Local values ──────────────────────────────────────────────────────────────

locals {
  common_tags = {
    # Functional tags
    env        = var.environment
    app        = var.project
    region     = var.region
    managed_by = "terraform"
    module     = "aks"
    # Accounting tags
    costcenter = var.cost_center
    # Ownership tags
    opsteam      = var.owner
    businessunit = var.business_unit
    # Classification tags
    criticality = var.criticality
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# KEY VAULT
# Created before AKS so we have somewhere to store the kubeconfig immediately
# after the cluster is provisioned.
#
# Key Vault uses RBAC authorization instead of the older access policies model.
# This means permissions are granted via Azure role assignments (like Storage
# Blob Data Contributor you used earlier) rather than vault-specific policies.
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_key_vault" "main" {
  name                = var.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Use Azure RBAC for access control instead of legacy vault access policies.
  # This is the recommended modern approach for Key Vault permissions.
  rbac_authorization_enabled = true

  # Soft delete keeps deleted secrets recoverable for 7 days.
  # This protects against accidental deletion of the kubeconfig.
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # false for dev — set true in prod

  tags = local.common_tags
}

# Grant the current Terraform service principal permission to write secrets.
# Without this, the kubeconfig secret creation below will fail with 403.
resource "azurerm_role_assignment" "kv_terraform_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ─────────────────────────────────────────────────────────────────────────────
# AKS CLUSTER
# The Kubernetes control plane managed by Azure.
# Azure handles the API server, etcd, and control plane upgrades.
# You only manage the node pools.
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  support_plan        = "KubernetesOfficial"


  # ── OIDC Issuer ─────────────────────────────────────────────────────────────
  # OIDC (OpenID Connect) Issuer exposes a public endpoint that Azure AD uses
  # to verify tokens issued by the cluster. This is the foundation that makes
  # Workload Identity work — without it, pods cannot prove their identity to
  # Azure services like Key Vault or Storage.
  oidc_issuer_enabled = true

  # ── Workload Identity ────────────────────────────────────────────────────────
  # Allows pods to authenticate to Azure services (Key Vault, Storage, ACR)
  # using a Kubernetes Service Account token — no passwords or secrets needed.
  # The pod gets a federated credential that Azure AD trusts via the OIDC issuer.
  workload_identity_enabled = true

  # ── System Node Pool ─────────────────────────────────────────────────────────
  # The default_node_pool is always the system pool.
  # It runs critical Kubernetes components: CoreDNS, kube-proxy, metrics-server.
  # Using on-demand VMs here ensures these never get evicted by Azure.
  default_node_pool {
    name                         = "system"
    node_count                   = var.system_node_count
    vm_size                      = var.system_node_vm_size
    vnet_subnet_id               = var.subnet_aks_id
    only_critical_addons_enabled = true

    node_labels = {
      "nodepool-type" = "npsystem"
      "env"           = var.environment
      "nodepoolos"    = "linux"
    }
  }

  # ── Identity ──────────────────────────────────────────────────────────────────
  # SystemAssigned gives AKS its own managed identity automatically.
  # Azure uses this identity to manage networking, pull from ACR etc.
  # No client secrets to rotate — Azure handles the credential lifecycle.
  identity {
    type = "SystemAssigned"
  }

  # ── Network profile ───────────────────────────────────────────────────────────
  # Azure CNI plugs each pod directly into the VNet subnet with its own IP.
  # This means pods are directly reachable from other Azure services in the VNet
  # (like the PostgreSQL private endpoint) without any NAT.
  network_profile {
    network_plugin    = "azure" # Azure CNI — pods get VNet IPs
    network_policy    = "azure" # Azure Network Policy — pod-level firewall rules
    load_balancer_sku = "standard"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# SPOT USER NODE POOL
# This is where your application pods run.
#
# Spot VMs are unused Azure capacity sold at up to 90% discount.
# The trade-off: Azure can evict them with 30 seconds notice when it needs
# the capacity back. For stateless microservices this is fine — the
# Cluster Autoscaler will replace evicted nodes automatically.
#
# Cluster Autoscaler keeps the pool between min and max nodes based on load.
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.spot_node_vm_size
  vnet_subnet_id        = var.subnet_aks_id

  # ── Spot configuration ────────────────────────────────────────────────────────
  priority        = "Spot"   # tells Azure to use spot pricing
  eviction_policy = "Delete" # delete the node (not deallocate) when evicted
  spot_max_price  = -1       # -1 means pay up to the on-demand price (safest option)

  # ── Cluster Autoscaler ────────────────────────────────────────────────────────
  # auto_scaling_enabled must be true to use min/max counts.
  # The autoscaler adds nodes when pods are pending due to insufficient resources
  # and removes nodes when they've been underutilised for 10+ minutes.
  auto_scaling_enabled = true
  min_count            = var.spot_node_min_count # 1 — always keep at least 1 node
  max_count            = var.spot_node_max_count # 3 — never exceed 3 nodes in dev

  # Spot nodes automatically get a taint that prevents regular pods from
  # scheduling here unless the pod explicitly tolerates it.
  # Our app pods will need to tolerate: kubernetes.azure.com/scalesetpriority=spot:NoSchedule
  node_labels = {
    "nodepool-type"                         = "np"
    "env"                                   = var.environment
    "nodepoolos"                            = "linux"
    "kubernetes.azure.com/scalesetpriority" = "spot"
  }

  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
  ]

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# KUBECONFIG SECRET IN KEY VAULT
# Stores the cluster credentials in Key Vault immediately after AKS is created.
# Team members with Key Vault Secrets User role can download it to connect.
#
# The kubeconfig contains the API server URL, cluster CA certificate, and
# the client credentials needed to run kubectl commands against the cluster.
# ─────────────────────────────────────────────────────────────────────────────

# resource "azurerm_key_vault_secret" "kubeconfig" {
#   name         = "aks-kubeconfig-${var.environment}"
#   value        = azurerm_kubernetes_cluster.main.kube_config_raw
#   key_vault_id = azurerm_key_vault.main.id

#   # Wait for the role assignment to fully propagate before writing the secret.
#   # Azure RBAC propagation can take up to 30 seconds — depends_on ensures
#   # Terraform waits rather than racing ahead and hitting a 403.
#   depends_on = [azurerm_role_assignment.kv_terraform_secrets_officer]

#   tags = local.common_tags
# }
