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
  description = "Name of the Redis cache instance."
  type        = string
  default     = "medlink-redis"
}

variable "sku_name" {
  description = "Redis SKU. Basic C0 is sufficient for dev."
  type        = string
  default     = "Basic"
}

variable "family" {
  description = "Redis family. C = Basic/Standard, P = Premium."
  type        = string
  default     = "C"
}

variable "capacity" {
  description = "Redis cache size. 0 = 250MB (smallest)."
  type        = number
  default     = 0
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
