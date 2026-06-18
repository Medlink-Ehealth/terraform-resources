# ─────────────────────────────────────────────────────────────────────────────
# variables.tf
# All variable declarations for the root module.
# Actual values come from environments/dev.tfvars or environments/prod.tfvars
# passed at plan/apply time:
#   terraform plan -var-file=environments/dev.tfvars
# ─────────────────────────────────────────────────────────────────────────────

# ── Environment ───────────────────────────────────────────────────────────────

variable "environment" {
  description = "Deployment environment. e.g. 'dev', 'staging', 'prod'"
  type        = string
}

variable "location" {
  description = "Azure region to deploy all resources into."
  type        = string
}

# ── Resource Group ────────────────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Name of the Azure Resource Group."
  type        = string
}

# ── Tagging ───────────────────────────────────────────────────────────────────

variable "owner" {
  description = "Owner email for resource tagging and cost attribution."
  type        = string
}

variable "project" {
  description = "Project name for tagging."
  type        = string
  default     = "medlink"
}

variable "cost_center" {
  description = "Cost center for billing tags."
  type        = string
  default     = "medlink-engineering"
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "vnet_address_space" {
  description = "CIDR block for the VNet."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_aks_cidr" {
  description = "CIDR for AKS nodes subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_postgres_cidr" {
  description = "CIDR for PostgreSQL private endpoint subnet."
  type        = string
  default     = "10.0.2.0/24"
}

variable "subnet_gateway_cidr" {
  description = "CIDR for gateway subnet."
  type        = string
  default     = "10.0.3.0/24"
}

# ── AKS ───────────────────────────────────────────────────────────────────────

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster."
  type        = string
}

variable "system_node_vm_size" {
  description = "VM size for the system node pool."
  type        = string
  default     = "Standard_D2s_v4"
}

variable "spot_node_vm_size" {
  description = "VM size for the spot user node pool."
  type        = string
  default     = "Standard_D2s_v4"
}

variable "spot_node_min_count" {
  description = "Minimum nodes in spot pool."
  type        = number
  default     = 1
}

variable "spot_node_max_count" {
  description = "Maximum nodes in spot pool."
  type        = number
  default     = 3
}

variable "key_vault_name" {
  description = "Name of the Key Vault for storing kubeconfig."
  type        = string
  default     = "medlink-kv"
}


# ── Front Door ────────────────────────────────────────────────────────────────

variable "nginx_ingress_ip" {
  description = "External IP of the NGINX Ingress Controller — origin for Front Door."
  type        = string
}

variable "waf_mode" {
  description = "WAF mode — Detection for dev, Prevention for prod."
  type        = string
  default     = "Detection"
}

# ── Storage ───────────────────────────────────────────────────────────────────

variable "storage_account_name" {
  description = "Name of the storage account. Must be globally unique, 3-24 chars, lowercase and numbers only."
  type        = string
}

# ── ACR ───────────────────────────────────────────────────────────────────────

variable "acr_name" {
  description = "Globally-unique ACR name (5-50 lowercase alphanumeric chars)."
  type        = string
  default     = "crmedlinkdev001"
}

variable "acr_sku" {
  description = "ACR SKU. Allowed: Basic, Standard, Premium."
  type        = string
  default     = "Basic"
}

# ── CAF Tags ──────────────────────────────────────────────────────────────────

variable "region" {
  description = "Azure region label for tagging."
  type        = string
  default     = "australiaeast"
}

variable "business_unit" {
  description = "Business unit responsible for the resources."
  type        = string
  default     = "engineering"
}

variable "criticality" {
  description = "Resource criticality per CAF. Values: low, medium, high, mission-critical"
  type        = string
  default     = "low"
}

# ── GitHub OIDC (MED-100) ─────────────────────────────────────────────────────

variable "github_org" {
  description = "GitHub organisation that owns the repositories."
  type        = string
  default     = "Medlink-Ehealth"
}

variable "github_oidc_app_object_id" {
  description = "Object ID of the existing Entra app registration GitHub Actions authenticates as (medlink-gh-oidc-sp)."
  type        = string
  default     = "24b422a7-7654-4efc-922b-ef8beeb403b9"
}

variable "github_oidc_repositories" {
  description = "Repositories (without org prefix) to trust via GitHub OIDC."
  type        = list(string)
  default = [
    "medlink-backend",
    "medlink-frontend",
    "terraform-resources",
    "pipeline-templates",
    "Medlink-landingpage",
  ]
}

variable "github_oidc_environments" {
  description = "GitHub Environment names to trust for each repo (subject environment:<name>)."
  type        = list(string)
  default     = ["dev"]
}
