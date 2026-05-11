# ─────────────────────────────────────────────────────────────────────────────
# modules/aks/variables.tf
# All inputs the calling environment must pass in.
# ─────────────────────────────────────────────────────────────────────────────

# ── Resource placement ────────────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Name of the Azure Resource Group to deploy AKS into."
  type        = string
}

variable "location" {
  description = "Azure region. Must match the region of the VNet."
  type        = string
  default     = "eastus2"
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "subnet_aks_id" {
  description = "Resource ID of the AKS nodes subnet from the network module output."
  type        = string
  # This is passed in from module.network.subnet_aks_id in environments/dev/main.tf
  # so we never hardcode a subnet ID anywhere.
}

# ── AKS Cluster ───────────────────────────────────────────────────────────────

variable "cluster_name" {
  description = "Name of the AKS cluster. CAF format: aks-{workload}-{env}"
  type        = string
  default     = "aks-medlink-dev"
}
variable "kubernetes_version" {
  description = "Kubernetes version to run on the cluster."
  type        = string
  default     = "1.29"
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster API server."
  type        = string
  default     = "medlink-dev"
}

# ── System Node Pool ──────────────────────────────────────────────────────────
# The system pool runs Kubernetes system pods (CoreDNS, kube-proxy etc.)
# It must always use on-demand (non-spot) VMs for stability.

variable "system_node_count" {
  description = "Number of nodes in the system node pool. Keep at 1 for dev."
  type        = number
  default     = 1
}

variable "system_node_vm_size" {
  description = "VM size for the system node pool."
  type        = string
  default     = "Standard_B2s"
}

# ── Spot User Node Pool ───────────────────────────────────────────────────────
# The user pool runs your application workloads.
# Spot VMs are up to 90% cheaper but can be evicted by Azure with 30s notice.
# The Cluster Autoscaler handles scaling within min/max bounds.

variable "spot_node_vm_size" {
  description = "VM size for the Spot user node pool."
  type        = string
  default     = "Standard_B2s"
}

variable "spot_node_min_count" {
  description = "Minimum nodes in the Spot user pool (Cluster Autoscaler lower bound)."
  type        = number
  default     = 1
}

variable "spot_node_max_count" {
  description = "Maximum nodes in the Spot user pool (Cluster Autoscaler upper bound)."
  type        = number
  default     = 3
}

# ── Key Vault ─────────────────────────────────────────────────────────────────

variable "key_vault_name" {
  description = "Name of the Azure Key Vault. CAF format: kv-{workload}-{env}"
  type        = string
  default     = "kv-medlink-dev"
}

# ── Tagging ───────────────────────────────────────────────────────────────────

variable "environment" {
  description = "Deployment environment label. e.g. 'dev', 'staging', 'prod'"
  type        = string
}

variable "project" {
  description = "Project name for tagging."
  type        = string
  default     = "medlink"
}

variable "owner" {
  description = "Owner email for tagging and cost attribution."
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing tags."
  type        = string
  default     = "medlink-engineering"
}

variable "region" {
  description = "Azure region label for tagging."
  type        = string
  default     = "australiaeast"
}

variable "business_unit" {
  description = "Business unit responsible for this resource."
  type        = string
  default     = "engineering"
}

variable "criticality" {
  description = "Resource criticality. CAF values: low, medium, high, mission-critical"
  type        = string
  default     = "low"
}
