# ─────────────────────────────────────────────────────────────────────────────
# modules/network/variables.tf
# All inputs the calling environment must pass in.
# ─────────────────────────────────────────────────────────────────────────────

# ── Resource placement ────────────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Name of the Azure Resource Group to deploy networking resources into."
  type        = string
}

variable "location" {
  description = "Azure region for all networking resources. e.g. 'eastus2'"
  type        = string
  default     = "eastus2"
}

# ── VNet ──────────────────────────────────────────────────────────────────────

variable "vnet_name" {
  description = "Name of the Virtual Network. CAF format: vnet-{workload}-{region}-{instance}"
  type        = string
  default     = "vnet-medlink-aue-001"
}

variable "vnet_address_space" {
  description = "CIDR block for the entire VNet."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

# ── Subnets ───────────────────────────────────────────────────────────────────

variable "subnet_aks_name" {
  description = "Name of the AKS nodes subnet. CAF format: snet-{purpose}-{region}-{instance}"
  type        = string
  default     = "snet-aks-aue-001"
}

variable "subnet_aks_cidr" {
  description = "CIDR block for AKS nodes subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_postgres_name" {
  description = "Name of the PostgreSQL private endpoint subnet. CAF format: snet-{purpose}-{region}-{instance}"
  type        = string
  default     = "snet-psql-aue-001"
}

variable "subnet_postgres_cidr" {
  description = "CIDR block for PostgreSQL private endpoint subnet."
  type        = string
  default     = "10.0.2.0/24"
}

variable "subnet_gateway_name" {
  description = "Name of the gateway subnet. CAF format: snet-{purpose}-{region}-{instance}"
  type        = string
  default     = "snet-gw-aue-001"
}

variable "subnet_gateway_cidr" {
  description = "CIDR block for the gateway subnet."
  type        = string
  default     = "10.0.3.0/24"
}

# ── Tagging ───────────────────────────────────────────────────────────────────

variable "environment" {
  description = "Deployment environment label. e.g. 'dev', 'staging', 'prod'"
  type        = string
}

variable "project" {
  description = "Project name used for tagging all resources."
  type        = string
  default     = "medlink"
}

variable "owner" {
  description = "Owner email for tagging — useful for cost attribution."
  type        = string
}

variable "cost_center" {
  description = "Cost center code for billing tags."
  type        = string
  default     = "medlink-engineering"
}

variable "region" {
  description = "Azure region label for tagging. e.g. 'australiaeast'"
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
