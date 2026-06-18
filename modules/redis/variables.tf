# ─────────────────────────────────────────────────────────────────────────────
# modules/redis/variables.tf
# MED-19: Azure Cache for Redis (TLS enforced)
# Owner: Michael Olomide
# ─────────────────────────────────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Name of the Azure Resource Group."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "redis_name" {
  description = "Name of the Managed Redis instance."
  type        = string
  default     = "medlink-redis"
}

variable "sku_name" {
  description = "Azure Managed Redis SKU. Balanced_B0 is the smallest (dev)."
  type        = string
  default     = "Balanced_B0"
}

variable "high_availability_enabled" {
  description = "Enable zone-redundant high availability. Disabled for dev to save cost; enable in prod."
  type        = bool
  default     = false
}

variable "key_vault_id" {
  description = "Key Vault ID to store Redis connection string."
  type        = string
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
}

variable "project" {
  description = "Project name for tagging."
  type        = string
  default     = "medlink"
}

variable "owner" {
  description = "Owner email for tagging."
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
  default     = ""
}

variable "business_unit" {
  description = "Business unit responsible for the resources."
  type        = string
  default     = "engineering"
}

variable "criticality" {
  description = "Resource criticality per CAF. Values: low, medium, high, mission-critical."
  type        = string
  default     = "low"
}
